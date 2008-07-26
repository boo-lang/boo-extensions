namespace Boo.PatternMatching.Tests

import NUnit.Framework
import Boo.PatternMatching
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

[TestFixture]
class CodeMatchingTest:
	
	[Test]
	def TestAssignment():
		
		code = [| a = 21*2 |]
		
		Assert.AreEqual("a", variableName(code))
		Assert.AreEqual(code.Right, rvalue(code))
		
	def variableName(code as Expression):
		match code:
			case [| $(ReferenceExpression(Name: l)) = $_ |]:
				return l
				
	def rvalue(code as Expression):
		match code:
			case [| $_ = $r |]:
				return r