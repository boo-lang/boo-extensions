namespace Boo.OMeta.Tests

import Boo.OMeta
import Boo.PatternMatching
import Boo.Adt
import NUnit.Framework

data Exp = Const(value as int)

[TestFixture]
class ObjectMatchingTest:
	
	[Test]
	def PropertyPatternMatching():
		
		ometa ConstList:
			parse = ++(Const(value) ^ value)
			
		match ConstList().parse(OMetaInput.For([Const(1), Const(42)])):
			case SuccessfulMatch(Input, Value):
				assert Input.IsEmpty
				Assert.AreEqual([1, 42], Value)