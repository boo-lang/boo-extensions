namespace Boo.OMeta

import Boo.Adt
import System.Collections.Generic
import System.Collections.Specialized

interface OMetaEvaluationContext:
	def Eval(rule as string, input as OMetaInput) as OMetaMatch

class NullEvaluationContext(OMetaEvaluationContext):
	
	final _grammar as OMetaGrammar
	
	def constructor([required] grammar as OMetaGrammar):
		_grammar = grammar
		
	def Eval(rule as string, input as OMetaInput) as OMetaMatch:
		return _grammar.Apply(self, rule, input)

class RuleSet(Set[of string]):
	def constructor():
		super()
	def constructor(other as RuleSet):
		super(other)

data LeftRecursion(@seed as OMetaMatch, rule as string, @head as Head)
data Head(rule as string, involvedSet as RuleSet, @evalSet as RuleSet)

class OMetaEvaluationContextImpl(OMetaEvaluationContext):
"""
Evaluation context with full support
for indirectly/mutually left recursive rules.
"""
	
	final _memo = HybridDictionary()
	
	final _lrStack = Stack[of LeftRecursion]()
	
	final _heads = HybridDictionary()
	
	final _grammar as OMetaGrammar
	
	def constructor([required] grammar as OMetaGrammar):
		_grammar = grammar
		
	def Eval(rule as string, input as OMetaInput) as OMetaMatch:	
		memoKey = MemoKey(rule, input)
		m = Recall(memoKey)
		if m is null:
			lr = LeftRecursion(Fail(input), rule, null)
			_lrStack.Push(lr)
			_memo[memoKey] = lr
			ans = Apply(rule, input)
			_lrStack.Pop()
			if lr.head is not null:
				lr.seed = ans
				return LRAnswer(memoKey, lr)
			else:
				_memo[memoKey] = ans
				return ans
		else:
			lr = m as LeftRecursion
			if lr is not null:
				SetupLR(rule, lr)
				return lr.seed
			else:
				return m
				
	private def Apply(rule as string, input as OMetaInput):
		return _grammar.Apply(self, rule, input)
				
	def Fail(input as OMetaInput):
		return FailedMatch(input, LeftRecursionFailure())
				
	def SetupLR(rule as string, lr as LeftRecursion):
		if lr.head is null:
			lr.head = Head(rule, RuleSet(), RuleSet())
			
		head = lr.head
		for s in _lrStack:
			break if s.head is head
			s.head = head
			head.involvedSet.Add(s.rule)
			
	def LRAnswer(memoKey as MemoKey, lr as LeftRecursion):
		h = lr.head
		r = memoKey.rule
		if h.rule != r:
			return lr.seed
		_memo[memoKey] = lr.seed
		if lr.seed isa FailedMatch:
			return lr.seed
		return GrowLR(memoKey, lr)
				
	def Recall(memoKey as MemoKey):
		m = _memo[memoKey]
		input = memoKey.input
		h as Head = _heads[input]
		if h is null:
			return m
			
		r = memoKey.rule
		if m is null and h.rule != r and not h.involvedSet.Contains(r):
			return Fail(input)
		if h.evalSet.Contains(r):
			h.evalSet.Remove(r)
			m = Apply(r, input)
			if _memo[memoKey] is null or (not (m isa FailedMatch and _memo[memoKey] isa SuccessfulMatch) ):
				_memo[memoKey] = m
			else:
				return _memo[memoKey]
		return m
		
	def GrowLR(memoKey as MemoKey, lr as LeftRecursion):	
		rule = memoKey.rule

		input = memoKey.input
		h = lr.head
		lastSuccessfulMatch as OMetaMatch = lr.seed
	
		_heads[input] = h
		while true:
			h.evalSet = RuleSet(h.involvedSet)
			m = Apply(rule, input)
			if m isa FailedMatch or m.Input.Position <= lastSuccessfulMatch.Input.Position:
				break
			_memo[memoKey] = lastSuccessfulMatch = m
			
		_heads.Remove(input)
		return lastSuccessfulMatch