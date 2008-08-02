namespace Boo.OMeta

import System.Collections.Specialized

class OMetaGrammarBase(OMetaGrammar):
		
	_rules = ListDictionary()
	
	def InstallRule(ruleName as string, rule as OMetaRule):
		_rules[ruleName] = rule
		
	def Eval(context as OMetaGrammar, rule as string, input as OMetaInput):
		found as OMetaRule = _rules[rule]
		if found is not null:
			return found(context, input)
		return RuleMissing(context, rule, input)
		
	virtual def Apply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return Eval(context, rule, input)
		
	virtual def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return Eval(context, rule, input)
		
	virtual def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch:
		raise "Rule '${rule}' missing!"
