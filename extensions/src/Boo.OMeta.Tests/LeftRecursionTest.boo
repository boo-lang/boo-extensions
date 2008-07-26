namespace Boo.OMeta.Tests


import Boo.OMeta
import Boo.PatternMatching

import NUnit.Framework

[TestFixture]
class LeftRecursionTest:
	[Test]
	def TestFailure():
		ometa E:
			expr = subtraction
			num = ++digit
			subtraction = expr, '-', num
			
		match E().expr(OMetaInput.For("2-1")):
			case FailedMatch(Input):
				Assert.AreEqual('2', Input.Head.ToString())