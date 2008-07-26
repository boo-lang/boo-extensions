namespace Boo.OMeta

import Boo.Adt
import System.Collections.Generic

data OMetaMatch(Input as OMetaInput) = SuccessfulMatch(Value as object) | FailedMatch()

callable OMetaRule(context as OMetaGrammar, input as OMetaInput) as OMetaMatch

interface OMetaGrammar:
	
	def InstallRule(ruleName as string, rule as OMetaRule)
	def Apply(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch
	def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch

class OMetaGrammarRoot(OMetaGrammar):
	
	_rules = Dictionary[of string, OMetaRule]()
	
	def InstallRule(ruleName as string, rule as OMetaRule):
		_rules[ruleName] = rule
	
	def Apply(context as OMetaGrammar, rule as string, input as OMetaInput):
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
		
class OMetaDelegatingGrammar(OMetaGrammarRoot):
	
	_prototype as OMetaGrammar
	
	def constructor(prototype as OMetaGrammar):
		_prototype = prototype
		
	override def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput):
		return SuperApply(context, rule, input)
		
	override def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return _prototype.SuperApply(context, rule, input)
		
def makeRule(predicate as System.Predicate[of object]) as OMetaRule:
	def rule(context as OMetaGrammar, input as OMetaInput) as OMetaMatch:
		if not input.IsEmpty and predicate(input.Head):
			return SuccessfulMatch(input.Tail, input.Head)
		return FailedMatch(input)
	return rule
