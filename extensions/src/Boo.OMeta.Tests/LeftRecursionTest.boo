namespace Boo.OMeta.Tests


import Boo.OMeta
import Boo.PatternMatching

import NUnit.Framework

[TestFixture]
class LeftRecursionTest:
	
	[Test]
	def DirectLeftRecursion():
		
		ometa DLR:
			option ParseTree
			expr = (expr, "-", num) | num
			num = ++digit >> ds ^ join(ds, '')
			
		match DLR().expr("1-2-3"):
			case SuccessfulMatch(
					Input: OMetaInput(IsEmpty: true),
					Value: [['1', '-', '2'], '-', '3']):
				pass
			
	[Test]
	def FailsOnIndirectRecursion():
		ometa ILR:
			expr = subtraction
			num = ++digit
			subtraction = expr, '-', num
			
		match ILR().expr(OMetaInput.For("2-1")):
			case FailedMatch(Input):
				Assert.AreEqual('2', Input.Head.ToString())