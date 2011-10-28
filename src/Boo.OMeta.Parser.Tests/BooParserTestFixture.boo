namespace Boo.OMeta.Parser.Tests

import System.IO

import Boo.Lang.Compiler.Ast
import Boo.OMeta
import Boo.OMeta.Parser
import Boo.Lang.PatternMatching
import Boo.Lang.Useful.Attributes
import NUnit.Framework

partial class BooParserTestFixture:

	def runTestCase(fname as string):
		
		fullName = Path.Combine(booRoundtripTestCasesPath(), fname)
		
		parser = BooParser()
		match parser.module(File.ReadAllText(fullName)):
			case SuccessfulMatch(Input: input, Value: m=Module()):
				assert m is not null
				assert m.Documentation is not null
				Assert.AreEqual(normalize(m.Documentation), normalize(m.ToCodeString()))
				assert input.IsEmpty, input.ToString()


	[Test]
	def TestEndSourceLocationForInlineClosures():
		code = """foo = { a = 3;
return a; }"""
		EnsureClosureEndSourceLocation(code, 2, 10)
		
		
	[Test]
	def TestEndSourceLocationForBlockClosures():
		code = """
foo = def():
    return a
"""
		EnsureClosureEndSourceLocation(code, 3, 13)
		

	def EnsureClosureEndSourceLocation(code as string, line as int, column as int):		
		parser = BooParser()
		
		match parser.module(code):
			case SuccessfulMatch(Input: input, Value: m=Module()):
				assert m is not null
				assert input.IsEmpty, input.ToString()
				e = (m.Globals.Statements[0] as ExpressionStatement).Expression
				cbe = (e as BinaryExpression).Right as BlockExpression
				esl = cbe.Body.EndSourceLocation
				Assert.AreEqual(line, esl.Line)
				Assert.AreEqual(column, esl.Column)

	def normalize(s as string):
		return s.Trim().Replace("\r\n", "\n")
		
	[once] def booRoundtripTestCasesPath():
		
		return Path.Combine(
					findSiblingBooDirectory(parentDirectory(System.Environment.CurrentDirectory)),
					"tests/testcases/parser/roundtrip")
		
	def findSiblingBooDirectory(dir as string) as string:
		
		booDir = Path.Combine(dir, "boo")
		if Directory.Exists(booDir): return booDir
		
		parent = parentDirectory(dir)
		assert parent != dir
		return findSiblingBooDirectory(parent)
		
	def parentDirectory(dir as string):
		return Path.GetDirectoryName(dir)