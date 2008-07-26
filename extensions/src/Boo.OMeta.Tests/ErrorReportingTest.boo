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
	
	[Test]
	def Sequence():
		
		match FailureParser().sequence("aa"):
			case FailedMatch(
					Input: OMetaInput(Position: 1),
					Failure: PredicateFailure(Rule: 'digit')):
				pass
				
	[Test]
	def EndOfInput():
		
		match FailureParser().sequence(""):
			case FailedMatch(Failure: EndOfInputFailure(Rule: 'letter')):
				pass
				
	[Test]
	def Predicate():
		
		match FailureParser().predicate("b"):
			case FailedMatch(
					Input: OMetaInput(Position: 0),
					Failure: PredicateFailure(Rule: "(l == char('a'))")):
				pass
		
		
		