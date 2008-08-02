namespace Boo.OMeta

import System.Collections.Specialized

class OMetaGrammarRoot(OMetaGrammarBase):
"""
OMetaGrammar with support for direct left recursion but no support for indirect left recursion.
"""
	_memo = HybridDictionary()
	
	override def Apply(context as OMetaGrammar, rule as string, input as OMetaInput):
		
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
		
	
