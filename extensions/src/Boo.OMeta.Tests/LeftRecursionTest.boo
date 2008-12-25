namespace Boo.OMeta.Tests


import Boo.OMeta
import Boo.Lang.PatternMatching

import NUnit.Framework

[TestFixture]
class LeftRecursionTest:
	
	[Test]
	def DirectLeftRecursion():
		
		ometa DLR:
			option ParseTree
			expr = (expr, "-", num) | num
			num = ++digit >> ds ^ join(ds, '')
			
		match DLR().expr("47-2-3"):
			case SuccessfulMatch(
					Input: OMetaInput(IsEmpty: true),
					Value: [['47', '-', '2'], '-', '3']):
				pass
			
	[Test]
	def IndirectLeftRecursion():
		ometa ILR:
			option ParseTree
			term = subtraction | factor
			subtraction = term, '-', factor
			factor = num
			num = ++digit >> ds ^ join(ds, '')
			
		match ILR().term(OMetaInput.For("2-1")):
			case SuccessfulMatch(
					Input: OMetaInput(IsEmpty: true),
					Value: ['2', '-', '1']):
				pass
				
	[Test]
	def IndirectLeftRecursionOnExtension():
		ometa ILRX < ILR:
			option ParseTree
			factor = (factor, '*', super) | super
			
		def test(code as string, expected):
			match ILRX().Apply('term', code):
				case SuccessfulMatch(
						Input: OMetaInput(IsEmpty: true),
						Value: actual):
					Assert.AreEqual(expected, actual)
					
		test "2*2*2", [['2', '*', '2'], '*', '2']
		test "42", '42'
		test "42-3*2", ['42', '-', ['3', '*', '2']]

