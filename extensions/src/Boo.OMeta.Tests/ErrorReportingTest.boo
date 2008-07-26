namespace Boo.OMeta.Tests

import Boo.OMeta
import Boo.PatternMatching
import NUnit.Framework

ometa FailureParser:
	sequence = letter, digit
	choice = letter | digit
	predicate = letter >> l and (l == char('a'))
		

[TestFixture]
class ErrorReportingTest:
	
#	[Test]
#	def Choice():
#		
#		match FailureParser().choice("_"):
#			case FailedMatch(
#					Input: OMetaInput(Position: 1),
#					Failure: ChoiceFailure(
#								Failures: [
#									FailedMatch(Failure: RuleFailure(Rule: 'letter')),
#									FailedMatch(Failure: RuleFailure(Rule: 'digit'))
#								])):
#				pass
	
	[Test]
	def Sequence():
		
		match FailureParser().sequence("aa"):
			case FailedMatch(
					Input: OMetaInput(Position: 1),
					Failure: RuleFailure(Rule: 'digit')):
				pass
				
	[Test]
	def EndOfInput():
		
		match FailureParser().sequence(""):
			case FailedMatch(
					Failure: RuleFailure(
								Rule: 'letter',
								Reason: EndOfInputFailure())):
				pass
				
	[Test]
	def Predicate():
		
		match FailureParser().predicate("b"):
			case FailedMatch(
					Input: OMetaInput(Position: 0),
					Failure: PredicateFailure(Predicate: "(l == char('a'))")):
				pass
		
		
		