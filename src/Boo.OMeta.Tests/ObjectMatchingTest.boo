namespace Boo.OMeta.Tests

import Boo.OMeta
import Boo.Lang.PatternMatching
import Boo.Adt
import NUnit.Framework

data Exp = Const(value as int) | Sum(left as Exp, right as Exp)

[TestFixture]
class ObjectMatchingTest:
	
	[Test]
	def PropertyPatternMatching():
		ometa ConstList:
			option ParseTree
			parse = ++(Const(value) ^ value)
			
		match ConstList().parse(OMetaInput.For([Const(1), Const(42)])):
			case SuccessfulMatch(Input, Value):
				assert Input.IsEmpty
				Assert.AreEqual([1, 42], Value)
		
	[Test]
	def PropertyParsing():
		ometa Evaluator:
			eval = const | sum
			const = Const(value) ^ value
			sum = Sum(left: eval >> l as int, right: eval >> r as int) ^ (l + r)
				
		match Evaluator().eval(OMetaInput.Singleton(Sum(Const(21), Sum(Const(11), Const(10))))):
			case SuccessfulMatch(Input, Value):
				assert Input.IsEmpty
				Assert.AreEqual(42, Value)
				
	[Test]
	def StringFieldMatchingWithCustomRule():
			
		data Person(name)
		
		ometa JohnOrPaulMatcher:
			john = "John "
			paul = "Paul "
			john_or_paul = john | paul
			match = Person(name: string[john_or_paul] >> _)
			string[rule] = $(string_matching(rule, input, context))
		
		def john_or_paul(person): 
			return JohnOrPaulMatcher().match(OMetaInput.Singleton(person))
		
		match john_or_paul(Person("John Stewart")):
			case SuccessfulMatch(Input):
				assert Input.IsEmpty
				
		match john_or_paul(Person("Paul Jones")):
			case SuccessfulMatch(Input):
				assert Input.IsEmpty
				
		match john_or_paul(Person("Eric")):
			case FailedMatch(Input):
				assert Input.Head == "Eric"
				
		match john_or_paul(Person(42)):
			case FailedMatch(Input, Failure: ObjectPatternFailure(Pattern)):
				assert Input.Head == 42
				assert Pattern == "'42' is not a string"
				
	static def string_matching(rule as string, input as OMetaInput, context as OMetaEvaluationContext):
		match input.Head:
			case s = string():
				match context.Eval(rule, OMetaInput.For(s)):
					case SuccessfulMatch():
						return SuccessfulMatch(input.Tail, input.Head)
					case FailedMatch(Failure):
						return FailedMatch(input, Failure)
			otherwise:
				return FailedMatch(input, ObjectPatternFailure("'$(input.Head)' is not a string"))