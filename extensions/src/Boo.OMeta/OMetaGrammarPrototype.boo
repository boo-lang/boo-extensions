namespace Boo.OMeta

class OMetaGrammarPrototype(OMetaGrammarRoot):
	
	def constructor():
		SetUpRule "whitespace", "char.IsWhitespace", char.IsWhiteSpace
		SetUpRule "letter", "char.IsLetter", char.IsLetter
		SetUpRule "digit", "char.IsDigit", char.IsDigit
		SetUpRule "_", "_", { o | return true }
		
	private def SetUpRule(name as string, predicateDescription as string, predicate as System.Predicate[of object]):
		InstallRule(name, makeRule(name, predicateDescription, predicate))
		
	def makeRule(ruleName as string, predicateDescription as string, predicate as System.Predicate[of object]) as OMetaRule:
		predicateFailure = PredicateFailure(predicateDescription)
		def rule(context as OMetaGrammar, input as OMetaInput) as OMetaMatch:
			if input.IsEmpty:
				return FailedMatch(input, RuleFailure(ruleName, EndOfInput))
			if  not predicate(input.Head):
				return FailedMatch(input, RuleFailure(ruleName, predicateFailure))
			return SuccessfulMatch(input.Tail, input.Head)
		return rule