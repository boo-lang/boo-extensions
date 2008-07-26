namespace Boo.OMeta

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.PatternMatching
import Boo.Adt

let currentRuleName = DynamicVariable[of string]()

macro ometa:
	
	def enclosingTypeDefinition():
		type as TypeDefinition = ometa.GetAncestor(NodeType.ClassDefinition) or ometa.GetAncestor(NodeType.Module)
		return type
		
	def expressions():
		for stmt in ometa.Block.Statements:
			match stmt:
				case ExpressionStatement(Expression: e):
					yield e
		
	def expandGrammarSetup():
		block = Block()
		for e in expressions():
			match e:
				case [| $(ReferenceExpression(Name: name)) = $pattern |]:
					currentRuleName.With(name):
						code = [|
							block:
								InstallRule($name) do(grammar as OMetaGrammar, input as OMetaInput):
									//print "> ${$name}"
									//try:
										$(expand(pattern))
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
	for e in expressions():
		match e:
			case [| $(ReferenceExpression(Name: name)) = $_ |]:
				m = [|
					def $name(input as OMetaInput):
						return Apply($name, input)
				|]
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
	
def expand(e as Expression) as Block:
	temp = [| lastMatch |]
	block = expand(e, [| input |], temp)
	block.LexicalInfo = e.LexicalInfo
	block.Add([| return $temp |])
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
	
def expandRepetition(block as Block, e as Expression, input as Expression, lastMatch as ReferenceExpression):
	
	temp = lastMatch #uniqueName()
	result = uniqueName()
	code = [|
		block:
			$(expand(e, input, temp))
			smatch = $temp as SuccessfulMatch
			if smatch is not null:
				$result = [smatch.Value]
				while true:
					$(expand(e, [| $temp.Input |], temp))
					smatch = $temp as SuccessfulMatch
					break if smatch is null
					$result.Add(smatch.Value)

				$lastMatch = SuccessfulMatch($temp.Input, $result )
	|].Block
	block.Add(code)	
	
def uniqueName():
	return ReferenceExpression(Name: "temp${CompilerContext.Current.AllocIndex()}")
	
def collectChoices(choices as List, e as Expression):
	match e:
		case [| $l | $r |]:
			collectChoices choices, l
			collectChoices choices, r
		otherwise:
			choices.Add(e)
			
def expandSequence(block as Block, sequence as ExpressionCollection, input as Expression, lastMatch as ReferenceExpression):
	currentBlock = block
	
	values = uniqueName()
	currentBlock.Add([| $values = [] |])
	for item in sequence:
		expand currentBlock, item, input, lastMatch
		input = [| $lastMatch.Input |]
		currentBlock.Add([| smatch = $lastMatch as SuccessfulMatch |])
		code = [|
			if smatch is not null:
				$values.Add(smatch.Value)
		|]
		currentBlock.Add(code)
		currentBlock = code.TrueBlock
	currentBlock.Add([| $lastMatch = SuccessfulMatch(smatch.Input, $values) |])
	
def expand(block as Block, e as Expression, input as Expression, lastMatch as ReferenceExpression):
	
	match e:
		case [| $pattern ^ $value |]:
			expand block, pattern, input, lastMatch
			code = [|
				block:
					smatch = $lastMatch as SuccessfulMatch
					if smatch is not null:
						$lastMatch = SuccessfulMatch(smatch.Input, $value)
			|].Block
			block.Add(code)
			
		case [| $pattern >> $variable |]:
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
			
		case ReferenceExpression(Name: name):
			block.Add([| $lastMatch = grammar.Apply(grammar, $name, $input) |])
			
		case [| super |]:
			block.Add([| $lastMatch = grammar.SuperApply(grammar, $(currentRuleName.Value), $input) |])
			
		case ArrayLiteralExpression(Items: items):
			expandSequence block, items, input, lastMatch 
