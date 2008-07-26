namespace Boo.OMeta

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.PatternMatching

macro ometa:
	
	def enclosingTypeDefinition():
		type as TypeDefinition = ometa.GetAncestor(NodeType.ClassDefinition) or ometa.GetAncestor(NodeType.Module)
		return type
		
	def expressions():
		for stmt in ometa.Block.Statements:
			match stmt:
				case ExpressionStatement(Expression: e):
					yield e
				otherwise:
					pass
		
	def expandGrammarSetup():
		block = Block()
		for e in expressions():
			match e:
				case [| $(ReferenceExpression(Name: name)) = $pattern |]:
					code = [|
						block:
							InstallRule($name) do(grammar as OMetaGrammar, input as OMetaInput):
								//print "> ${$name}"
								//try:
									$(RuleExpander(name).expand(pattern))
								//ensure:
								//	print "< ${$name}"
					|].Block
					block.Add(code)
		return block
		
	declaration = ometa.Arguments[0]
						
	type = [|
		class $(grammarName(declaration))(OMetaGrammar):
			
			_grammar as OMetaGrammar
				
			def constructor():
				_grammar = $(prototypeFor(declaration))
				$(expandGrammarSetup())
				
			def InstallRule(ruleName as string, rule as OMetaRule):
				_grammar.InstallRule(ruleName, rule)
		
			def OMetaGrammar.Apply(context as OMetaGrammar, rule as string, input as OMetaInput):
				return _grammar.Apply(context, rule, input)
				
			def OMetaGrammar.SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
				return _grammar.SuperApply(context, rule, input)
				
			def Apply(rule as string, input as OMetaInput):
				return _grammar.Apply(self, rule, input)
			
	|]
	for stmt in ometa.Block.Statements:
		match stmt:
			case ExpressionStatement(Expression: [| $(ReferenceExpression(Name: name)) = $_ |]):
				m = [|
					def $name(input as OMetaInput):
						return Apply($name, input)
				|]
				type.Members.Add(m)
				
			case DeclarationStatement(Declaration: Declaration(Name: name, Type: null), Initializer: block=BlockExpression()):
				m = Method(
						Name: name,
						LexicalInfo: block.LexicalInfo,
						Body: block.Body,
						Parameters: block.Parameters,
						ReturnType: block.ReturnType)
				
				type.Members.Add(m)
		
	type.LexicalInfo = ometa.LexicalInfo
	enclosingTypeDefinition().Members.Add(type)
	
def prototypeFor(e as Expression) as MethodInvocationExpression:
	match e:
		case [| $_ < $prototype |]:
			return [| OMetaDelegatingGrammar($prototype()) |]
		case ReferenceExpression():
			return [| OMetaGrammarPrototype() |]
	
def grammarName(e as Expression) as string:
	match e:
		case ReferenceExpression(Name: name):
			return name
		case [| $l < $_ |]:
			return grammarName(l)
			
class RuleExpander:
	
	_ruleName as string
	_collectingParseTree = DynamicVariable[of bool](true)

	def constructor(ruleName as string):
		_ruleName = ruleName
	
	def expand(e as Expression) as Block:
		block = expand(e, [| input |], [| lastMatch |])
		block.Add([| return lastMatch |])
		block.LexicalInfo = e.LexicalInfo
		return block
		
	def expand(e as Expression, input as Expression, lastMatch as ReferenceExpression) as Block:
		block = Block()
		expand block, e, input, lastMatch
		return block
		
	def expandChoices(block as Block, choices as List, input as Expression, lastMatch as ReferenceExpression):
		temp = uniqueName()
		
		currentBlock = block
		for choice in choices:
			expand currentBlock, choice, input, temp
			code = [|
				if $temp isa SuccessfulMatch:
					$lastMatch = $temp
				else:
					pass
			|]
			currentBlock.Add(code)
			currentBlock = code.FalseBlock
		currentBlock.Add([| $lastMatch = FailedMatch($input) |])
		
	def resultAppend(result as Expression):
		return [| $result.Add(smatch.Value) if smatch.Value is not null |]
		
	def expandRepetition(block as Block, e as Expression, input as Expression, lastMatch as ReferenceExpression):
		
		temp = lastMatch #uniqueName()
		result = uniqueName()
		code = [|
			block:
				$(expand(e, input, temp))
				smatch = $temp as SuccessfulMatch
				if smatch is not null:
					$result = []
					$(resultAppend(result))
					while true:
						$(expand(e, [| $temp.Input |], temp))
						smatch = $temp as SuccessfulMatch
						break if smatch is null
						$(resultAppend(result))
	
					$lastMatch = SuccessfulMatch($temp.Input, $result )
		|].Block
		block.Add(code)	
		
	def collectChoices(choices as List, e as Expression):
		match e:
			case [| $l | $r |]:
				collectChoices choices, l
				collectChoices choices, r
			otherwise:
				choices.Add(e)
				
	collectingParseTree:
		get: return _collectingParseTree.Value
				
	def expandSequence(block as Block, sequence as ExpressionCollection, input as Expression, lastMatch as ReferenceExpression):
		
		if collectingParseTree:
			expandSequenceWithParseTree block, sequence, input, lastMatch
		else:
			expandSequenceWithoutParseTree block, sequence, input, lastMatch
		
	def expandSequenceWithoutParseTree(block as Block, sequence as ExpressionCollection, input as Expression, lastMatch as ReferenceExpression):
		
		currentBlock = block
		for item in sequence.ToArray()[:-1]:
			expand currentBlock, item, input, lastMatch
			input = [| $lastMatch.Input |]
			code = [|
				if $lastMatch isa SuccessfulMatch:
					pass
			|]
			currentBlock.Add(code)
			currentBlock = code.TrueBlock
		expand currentBlock, sequence[-1], input, lastMatch
		
	def expandSequenceWithParseTree(block as Block, sequence as ExpressionCollection, input as Expression, lastMatch as ReferenceExpression):
		
		result = uniqueName()
		currentBlock = block
		currentBlock.Add([| $result = [] |])
		
		for item in sequence:
			expand currentBlock, item, input, lastMatch
			currentBlock.Add([| smatch = $lastMatch as SuccessfulMatch |])
			code = [|
				if smatch is not null:
					$(resultAppend(result))
			|]
			currentBlock.Add(code)
			currentBlock = code.TrueBlock
			input = [| $lastMatch.Input |]
			
		currentBlock.Add([| $lastMatch = SuccessfulMatch(smatch.Input, $result) |])
		
	def expandNegation(block as Block, rule as Expression, input as Expression, lastMatch as ReferenceExpression):
		oldInput = uniqueName()
		block.Add([| $oldInput = $input |])
		
		_collectingParseTree.With(false):
			expand block, rule, input, lastMatch
		block.Add([| smatch = $lastMatch as SuccessfulMatch |])
		code = [|
			if smatch is null:
				$lastMatch = SuccessfulMatch($oldInput, null)
			else:
				$lastMatch = FailedMatch($oldInput)
		|]
		block.Add(code)
		return code
		
	def expand(block as Block, e as Expression, input as Expression, lastMatch as ReferenceExpression):
		match e:
			case [| $pattern and $predicate |]:
				expand block, pattern, input, lastMatch
				checkPredicate = [|
					if $lastMatch isa SuccessfulMatch and not $predicate:
						$lastMatch = FailedMatch($input)
				|]
				block.Add(checkPredicate)
				
			case [| $pattern ^ $value |]:
				_collectingParseTree.With(false):
					expand block, pattern, input, lastMatch
					code = [|
						block:
							smatch = $lastMatch as SuccessfulMatch
							if smatch is not null:
								$lastMatch = SuccessfulMatch(smatch.Input, $value)
					|].Block
					block.Add(code)
				
			case [| $pattern >> $variable |]:
				_collectingParseTree.With(true):
					expand block, pattern, input, lastMatch
					code = [|
						block:
							smatch = $lastMatch as SuccessfulMatch
							if smatch is not null:
								$variable = smatch.Value
					|].Block
					block.Add(code)
				
			case [| $_ | $_ |]:
				choices = []
				collectChoices choices, e
				expandChoices block, choices, input, lastMatch
				
			case StringLiteralExpression():
				block.Add([| $lastMatch = string_($input, $e) |])
				
			case [| ++$rule |]:
				expandRepetition block, rule, input, lastMatch
				
			case [| ~$rule |]:
				expandNegation block, rule, input, lastMatch
				
			case ReferenceExpression(Name: name):
				block.Add([| $lastMatch = grammar.Apply(grammar, $name, $input) |])
				
			case [| super |]:
				block.Add([| $lastMatch = grammar.SuperApply(grammar, $_ruleName, $input) |])
				
			case [| $_() |]:
				rules = processObjectPatternRules(e)
				condition = PatternExpander().expand([| smatch.Value |], e)
				code = [|
					block:
						$lastMatch = any($input)
						smatch = $lastMatch as SuccessfulMatch
						if smatch is not null:
							if $condition:
								$(expandObjectPatternRules(rules, lastMatch))
							else:
								$lastMatch = FailedMatch($input)
				|].Block
				block.Add(code) 
				
			case ArrayLiteralExpression(Items: items):
				match items[0]:
					case [| ~$rule |]:
						negation = expandNegation(block, rule, input, lastMatch)
						if len(items) > 2:
							expandSequence negation.TrueBlock, items.PopRange(1), input, lastMatch
						else:
							expand negation.TrueBlock, items[1], input, lastMatch
					otherwise:
						expandSequence block, items, input, lastMatch 
				
	def processObjectPatternRules(pattern as Expression):
		rules = []
		processObjectPatternRules rules, pattern
		return rules
		
	def expandObjectPatternRules(rules, lastMatch as Expression) as Block:
		block = Block()
		input = uniqueName()
		
		currentBlock = block
		for temp as Expression, rule as Expression in rules:
			block.Add([| $input = OMetaInput.Singleton($temp) |])
			expand block, rule, input, lastMatch
			code = [|
				if $lastMatch isa SuccessfulMatch:
					pass
			|]
			currentBlock.Add(code)
			currentBlock = code.TrueBlock
		return block
		
	def processObjectPatternRules(rules as List, pattern as MethodInvocationExpression):
		for arg in pattern.NamedArguments:
			match arg.Second:
				case [| $_ >> $_ |]:
					temp = uniqueName()
					rules.Add((temp, arg.Second))
					arg.Second = temp
				otherwise:
					pass
			
def uniqueName():
	return ReferenceExpression(Name: "temp${CompilerContext.Current.AllocIndex()}")
