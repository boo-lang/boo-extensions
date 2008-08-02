namespace Boo.OMeta

import Boo.Adt

data OMetaMatch(Input as OMetaInput) = \
		SuccessfulMatch(Value as object) \
		| FailedMatch(Failure as OMetaFailure) \
		| LR(@detected as bool) // internal use only

callable OMetaRule(context as OMetaGrammar, input as OMetaInput) as OMetaMatch

interface OMetaGrammar:
	
	def InstallRule(ruleName as string, rule as OMetaRule)
	def Apply(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch
	def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput) as OMetaMatch

