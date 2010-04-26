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
