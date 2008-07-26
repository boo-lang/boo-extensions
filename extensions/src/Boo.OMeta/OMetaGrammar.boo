namespace Boo.OMeta

import System.Collections.Generic

callable OMetaRule(grammar as OMetaGrammar, input as OMetaInput) as OMetaMatch

class OMetaGrammar:
	
	_rules = Dictionary[of string, OMetaRule]()
	
	self[ruleName as string] as OMetaRule:
		set: _rules[ruleName] = value
	
	def Apply(rule as string, input as OMetaInput):
		return _rules[rule](self, input)
		