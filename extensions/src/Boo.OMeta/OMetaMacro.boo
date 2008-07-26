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
		
	grammarSetupBlock = Block()
	for e in expressions():
		match e:
			case [| $(ReferenceExpression(Name: name)) = $pattern |]:
				code = [|
					block:
						grammar[$name] = do(grammar as OMetaGrammar, input as OMetaInput):
							//print "> ${$name}"
							//try:
								$(expand(pattern))
							//ensure:
							//	print "< ${$name}"
				|].Block
				grammarSetupBlock.Add(code)
						
	grammarName as ReferenceExpression, = ometa.Arguments
	type = [|
		class $grammarName:
	
			_grammar as OMetaGrammar
			
			def constructor():
				grammar = OMetaGrammar()
				$grammarSetupBlock
				_grammar = grammar
	|]
	for e in expressions():
		match e:
			case [| $(ReferenceExpression(Name: name)) = $_ |]:
				m = [|
					def $name(input as OMetaInput):
						return _grammar.Apply($name, input)
				|]
				type.Members.Add(m)
		
	enclosingTypeDefinition().Members.Add(type)
	
def expand(e as Expression) as Block:
	temp = [| lastMatch |]
	block = expand(e, [| input |], temp)
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
	
	code = [|
		block:
			$(expand(e, input, temp))
			smatch = $temp as SuccessfulMatch
			if smatch is not null:
				result = [smatch.Value]
				while true:
					$(expand(e, [| $temp.Input |], temp))
					smatch = $temp as SuccessfulMatch
					break if smatch is null
					result.Add(smatch.Value)

				$lastMatch = SuccessfulMatch($temp.Input, result)
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
		case [| $l | $r |]:
			choices = []
			collectChoices choices, e
			expandChoices block, choices, input, lastMatch
			
		case StringLiteralExpression():
			block.Add([| $lastMatch = string_($input, $e) |])
			
		case [| ++$rule |]:
			expandRepetition block, rule, input, lastMatch
			
		case ReferenceExpression(Name: name):
			block.Add([| $lastMatch = grammar.Apply($name, $input) |])
			
		case ArrayLiteralExpression(Items: items):
			expandSequence block, items, input, lastMatch 
