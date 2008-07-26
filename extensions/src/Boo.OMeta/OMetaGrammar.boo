namespace Boo.OMeta

import System.Collections.Generic

callable OMetaRule(grammar as OMetaGrammar, input as OMetaInput) as OMetaMatch

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
		
class OMetaDelegatingGrammar(OMetaGrammarRoot):
	
	_prototype as OMetaGrammar
	
	def constructor(prototype as OMetaGrammar):
		_prototype = prototype
		
	override def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput):
		return SuperApply(context, rule, input)
		
	override def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return _prototype.SuperApply(context, rule, input)
			
		