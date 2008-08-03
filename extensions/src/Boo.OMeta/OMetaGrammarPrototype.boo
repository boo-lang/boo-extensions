namespace Boo.OMeta

class OMetaGrammarPrototype(OMetaGrammarBase):
	
	def constructor():
		SetUpRule "whitespace", "char.IsWhitespace", char.IsWhiteSpace
		SetUpRule "letter", "char.IsLetter", char.IsLetter
		SetUpRule "digit", "char.IsDigit", char.IsDigit
		InstallRule "_", any_rule
		
	private def SetUpRule(name as string, predicateDescription as string, predicate as System.Predicate[of object]):
		InstallRule(name, makeRule(name, predicateDescription, predicate))
		
	def makeRule(ruleName as string, predicateDescription as string, predicate as System.Predicate[of object]) as OMetaRule:
		predicateFailure = PredicateFailure(predicateDescription)
		def rule(context as OMetaEvaluationContext, input as OMetaInput) as OMetaMatch:
			if input.IsEmpty:
				return FailedMatch(input, RuleFailure(ruleName, EndOfInput))
			head = input.Head
			if head isa char and predicate(head):
				return SuccessfulMatch(input.Tail, head)
			return FailedMatch(input, RuleFailure(ruleName, predicateFailure))
			
		return rule