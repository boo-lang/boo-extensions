namespace Boo.OMeta.Parser.Tests

import Boo.OMeta
import Boo.OMeta.Parser
import Boo.PatternMatching

import Boo.Lang.Compiler.Ast

import NUnit.Framework

[TestFixture]
class BooParserTestCase:
	
	[Test]
	def TestSimpleModuleWithImport():
		
		code = """
import System.Console

WriteLine(42)
		"""
		
		m = parseModule(code)
		Assert.AreEqual(1, len(m.Imports))
		Assert.AreEqual("System.Console", m.Imports[0].Namespace)
		
	def parseModule(code as string) as Module:
		match BooParser().module(code):
			case SuccessfulMatch(Input: OMetaInput(IsEmpty: true), Value):
				return Value
		
		
		
		