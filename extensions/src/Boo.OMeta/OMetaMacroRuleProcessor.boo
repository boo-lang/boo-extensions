namespace Boo.OMeta

import Boo.Lang.Compiler.Ast
import Boo.PatternMatching

class OMetaMacroRuleProcessor:
	
	_ruleName as string
	_collectingParseTree as DynamicVariable[of bool]
	_optionParseTree as bool

	def constructor(ruleName as string, options as List):
		_ruleName = ruleName
		_optionParseTree = "ParseTree" in options
		_collectingParseTree = DynamicVariable[of bool](_optionParseTree)
	
	def expand(e as Expression, *args as (Expression)) as Block:
		
		input = [| input_ |]
		block = Block(LexicalInfo: e.LexicalInfo)
		for arg in args:
			code = [|
				block:
					lastMatch = any($input)
					smatch = lastMatch as SuccessfulMatch
					if smatch is null: return lastMatch
					$input = smatch.Input
					$arg = smatch.Value
			|].Block
			block.Add(code)
		
		expand block, e, input, [| lastMatch |]
		block.Add([| return lastMatch |])
		
		return block
		
	def expand(e as Expression, input as Expression, lastMatch as ReferenceExpression) as Block:
		block = Block()
		expand block, e, input, lastMatch
		return block
		
	def expandChoices(block as Block, choices as List, input as Expression, lastMatch as ReferenceExpression):
		currentBlock = block
		
		oldInput = uniqueName()
		failureList = uniqueName()
		currentBlock.Add([| $failureList = Boo.Lang.List[of FailedMatch]($(len(choices))) |])
		currentBlock.Add([| $oldInput = $input |])
		for choice in choices:
			expand currentBlock, choice, oldInput, lastMatch
			code = [|
				if $lastMatch isa FailedMatch:
					$failureList.Add($lastMatch)
			|]
			currentBlock.Add(code)
			currentBlock = code.TrueBlock
		currentBlock.Add([| $lastMatch = FailedMatch($oldInput, ChoiceFailure($failureList)) |])
		
	def resultAppend(result as Expression):
		if collectingParseTree:
			return [| $result.Add(smatch.Value) if smatch.Value is not null |]
		return ExpressionStatement([| $result = smatch.Value |])
		
	def expandRepetition(block as Block, e as Expression, input as Expression, lastMatch as ReferenceExpression):
		
		temp = lastMatch #uniqueName()
		result = uniqueName()
		block.Add(expand(e, input, temp))
		block.Add([| smatch = $temp as SuccessfulMatch |])
		code = [|
			if smatch is not null:
				$(resultAppend(result))
				$(expandRepetitionLoop(e, [| $temp.Input |], temp, result)) 
		|]
		if collectingParseTree:
			code.TrueBlock.Insert(0, [| $result = [] |])
		block.Add(code)	
		
	def expandRepetitionLoop(e as Expression, input as Expression, lastMatch as ReferenceExpression, result as Expression):
		tempInput = uniqueName()
		code = [|
			block:
				$tempInput = $input
				while true:
					$(expand(e, tempInput, lastMatch))
					smatch = $lastMatch as SuccessfulMatch
					break if smatch is null
					$tempInput = smatch.Input
					$(resultAppend(result))

				$lastMatch = SuccessfulMatch($tempInput, $result)
		|]
		return code.Block
		
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
		
		if _optionParseTree and collectingParseTree:
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
				$lastMatch = FailedMatch($oldInput, NegationFailure($(rule.ToCodeString())))
		|]
		block.Add(code)
		return code
		
	def processVariables(e as Expression, input as Expression):
		e.ReplaceNodes([| input |], [| $input |])
		return e
		
	def expand(block as Block, e as Expression, input as Expression, lastMatch as ReferenceExpression):
		match e:
			case SpliceExpression(Expression: rule):
				block.Add([| $lastMatch = $(processVariables(rule, input)) |])
				
			case [| $rule[$arg] |]:
				newInput = uniqueName()
				block.Add([| $newInput = OMetaInput.Prepend($arg, $input) |])
				expand block, rule, newInput, lastMatch
				
			case [| $pattern and $predicate |]:
				expand block, pattern, input, lastMatch
				checkPredicate = [|
					if $lastMatch isa SuccessfulMatch and not $(processVariables(predicate, input)):
						$lastMatch = FailedMatch($input, PredicateFailure($(predicate.ToCodeString())))
				|]
				block.Add(checkPredicate)
				
			case [| $pattern ^ $value |]:
				_collectingParseTree.With(false):
					expand block, pattern, input, lastMatch
					code = [|
						block:
							smatch = $lastMatch as SuccessfulMatch
							if smatch is not null:
								$lastMatch = SuccessfulMatch(smatch.Input, $(processVariables(value, input)))
					|].Block
					block.Add(code)
				
			case [| $pattern >> $variable |]:
				_collectingParseTree.With(true):
					expand block, pattern, input, lastMatch
					match variable:
						case [| $name as $typeref |]:
							code = [|
								block:
									smatch = $lastMatch as SuccessfulMatch
									if smatch is not null:
										$name = cast($typeref, smatch.Value)
							|].Block
						otherwise:
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
				
			case StringLiteralExpression(Value: v):
				if len(v) == 0:
					block.Add([| $lastMatch = SuccessfulMatch($input, null) |])
				elif len(v) == 1:
					block.Add([| $lastMatch = character($input, $(CharLiteralExpression(e.LexicalInfo, v[0]))) |])
				else:
					block.Add([| $lastMatch = characters($input, $e) |])
				
			case [| ++$rule |]:
				expandRepetition block, rule, input, lastMatch
				
			case [| --$rule |]:
				result = uniqueName()
				block.Add([| $result = [] |]) if collectingParseTree
				block.Add(expandRepetitionLoop(rule, input, lastMatch, result))
				
			case [| ~$rule |]:
				expandNegation block, rule, input, lastMatch
				
			case ReferenceExpression(Name: name):
				block.Add([| $lastMatch = context.Eval($name, $input) |])
				
			case [| super |]:
				block.Add([| $lastMatch = SuperApply(context, $_ruleName, $input) |])
				
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
								$lastMatch = FailedMatch($input, ObjectPatternFailure($(e.ToCodeString())))
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
			