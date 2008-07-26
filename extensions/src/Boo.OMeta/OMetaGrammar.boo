namespace Boo.OMeta

import Boo.Adt
import System.Collections.Generic

data OMetaMatch(Input as OMetaInput) = SuccessfulMatch(Value as object) \
		| FailedMatch() \
		| LR(@detected as bool) // internal use only

callable OMetaRule(context as OMetaGrammar, input as OMetaInput) as OMetaMatch

interface OMetaGrammar:
	
	def InstallRule(ruleName as string, rule as OMetaRule)
	def Apply(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch
	def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch

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
	
	_rules = Dictionary[of string, OMetaRule]()
	_memo = Dictionary[of MemoKey, OMetaMatch]()
	
	def InstallRule(ruleName as string, rule as OMetaRule):
		_rules[ruleName] = rule
	
	def Apply(context as OMetaGrammar, rule as string, input as OMetaInput):
		
		key = MemoKey(rule, input)
		m as OMetaMatch
		if not _memo.TryGetValue(key, m):
			lr = LR(input, false)
			_memo[key] = lr
			m = Eval(context, rule, input)
			_memo[key] = m
			if lr.detected and m isa SuccessfulMatch:
				return GrowLR(context, rule, input, key, m)
			else:
				return m
		else:
			lr = m as LR
			if lr is not null:
				lr.detected = true
				return FailedMatch(input)
			else:
				return m
		
	def GrowLR(context as OMetaGrammar, rule as string, input as OMetaInput, key, lastSuccessfulMatch as OMetaMatch):
		while true:			
			m = Eval(context, rule, input)
			if m isa FailedMatch or m.Input is input.Tail:
				break
			_memo[key] = lastSuccessfulMatch = m
		return lastSuccessfulMatch
		
	def Eval(context as OMetaGrammar, rule as string, input as OMetaInput):
		found as OMetaRule
		if _rules.TryGetValue(rule, found):
			return found(context, input)
		return RuleMissing(context, rule, input)
		
	def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return Apply(context, rule, input)
		
	virtual def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch:
		raise "Rule '${rule}' missing!"
		
class OMetaGrammarPrototype(OMetaGrammarRoot):
	
	def constructor():
		InstallRule("whitespace", makeRule(char.IsWhiteSpace))
		InstallRule("letter", makeRule(char.IsLetter))
		InstallRule("digit", makeRule(char.IsDigit))
		InstallRule("_", makeRule({ o | return true }))
		
class OMetaDelegatingGrammar(OMetaGrammarRoot):
	
	_prototype as OMetaGrammar
	
	def constructor(prototype as OMetaGrammar):
		_prototype = prototype
		
	override def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput):
		return _prototype.Apply(context, rule, input)
		
	override def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return _prototype.Apply(context, rule, input)
		
def makeRule(predicate as System.Predicate[of object]) as OMetaRule:
	def rule(context as OMetaGrammar, input as OMetaInput) as OMetaMatch:
		if not input.IsEmpty and predicate(input.Head):
			return SuccessfulMatch(input.Tail, input.Head)
		return FailedMatch(input)
	return rule
