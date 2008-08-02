namespace Boo.OMeta

import System.Collections.Specialized

class OMetaGrammarRoot(OMetaGrammar):
	
	class MemoKey:
		final _rule as string
		final _input as OMetaInput
		
		def constructor(rule as string, input as OMetaInput):
			_rule = rule
			_input = input
			
		override def Equals(o):
			other as MemoKey = o
			return _input is other._input and _rule is other._rule
			
		override def GetHashCode():
			return _rule.GetHashCode() ^ _input.GetHashCode()
			
		override def ToString():
			return "MemoKey(${_rule}, ${_input})"
	
	_rules = ListDictionary()
	_memo = HybridDictionary()
	
	def InstallRule(ruleName as string, rule as OMetaRule):
		_rules[ruleName] = rule
	
	def Apply(context as OMetaGrammar, rule as string, input as OMetaInput):
		
		memoKey = MemoKey(rule, input)
		m = _memo[memoKey]
		if m is null:
			lr = LR(input, false)
			_memo[memoKey] = lr
			m = Eval(context, rule, input)
			_memo[memoKey] = m
			if lr.detected and m isa SuccessfulMatch:
				return GrowLR(context, rule, input, m, memoKey)
			else:
				return m
		else:
			lr = m as LR
			if lr is not null:
				lr.detected = true
				return FailedMatch(input, LeftRecursionFailure())
			else:
				return m
		
	def GrowLR(context as OMetaGrammar, rule as string, input as OMetaInput, lastSuccessfulMatch as OMetaMatch, memoKey as MemoKey):
		while true:
			m = Eval(context, rule, input)
			if m isa FailedMatch or m.Input.Position <= lastSuccessfulMatch.Input.Position:
				break
			_memo[memoKey] = lastSuccessfulMatch = m
		return lastSuccessfulMatch
		
	def Eval(context as OMetaGrammar, rule as string, input as OMetaInput):
		found as OMetaRule = _rules[rule]
		if found is not null:
			return found(context, input)
		return RuleMissing(context, rule, input)
		
	def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return Apply(context, rule, input)
		
	virtual def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch:
		raise "Rule '${rule}' missing!"
