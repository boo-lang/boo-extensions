namespace Boo.OMeta

import System.Collections.Specialized

class OMetaEvaluationContextLR(OMetaEvaluationContext):
"""
Evaluation context with support for direct left recursion but no support for indirect left recursion.
"""
	_memo = HybridDictionary()
	
	_grammar as OMetaGrammar
	
	def constructor(grammar as OMetaGrammar):
		_grammar = grammar
	
	def Eval(rule as string, input as OMetaInput):
		
		memoKey = MemoKey(rule, input)
		m = _memo[memoKey]
		if m is null:
			lr = LR(input, false)
			_memo[memoKey] = lr
			m = _grammar.Apply(self, rule, input)
			_memo[memoKey] = m
			if lr.detected and m isa SuccessfulMatch:
				return GrowLR(rule, input, m, memoKey)
			else:
				return m
		else:
			lr = m as LR
			if lr is not null:
				lr.detected = true
				return FailedMatch(input, LeftRecursionFailure())
			else:
				return m
		
	def GrowLR(rule as string, input as OMetaInput, lastSuccessfulMatch as OMetaMatch, memoKey as MemoKey):
		while true:
			m = _grammar.Apply(self, rule, input)
			if m isa FailedMatch or m.Input.Position <= lastSuccessfulMatch.Input.Position:
				break
			_memo[memoKey] = lastSuccessfulMatch = m
		return lastSuccessfulMatch
		