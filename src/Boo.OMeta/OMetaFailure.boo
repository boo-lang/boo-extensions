namespace Boo.OMeta

import Boo.Adt

let EndOfInput = EndOfInputFailure()

data OMetaFailure() = \
		EndOfInputFailure() \
		| PredicateFailure(Predicate as string) \
		| NegationFailure(Predicate as string) \
		| LeftRecursionFailure() \
		| ExpectedValueFailure(Expected as object) \
		| ObjectPatternFailure(Pattern as string) \
		| ChoiceFailure(Failures as Boo.Lang.List[of FailedMatch]) \
		| RuleFailure(Rule as string, Reason as OMetaFailure)
