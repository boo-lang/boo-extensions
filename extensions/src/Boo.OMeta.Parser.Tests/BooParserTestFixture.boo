namespace Boo.OMeta.Parser.Tests

import System.IO

import Boo.Lang.Compiler.Ast
import Boo.OMeta
import Boo.OMeta.Parser
import Boo.PatternMatching

import NUnit.Framework

partial class BooParserTestFixture:

	def runTestCase(fname as string):
		
		fullName = Path.Combine(booRoundtripTestCasesPath(), fname)
		
		parser = BooParser()
		match parser.module(File.ReadAllText(fullName)):
			case SuccessfulMatch(Value: m=Module()):
				assert m is not null
				assert m.Documentation is not null
				Assert.AreEqual(normalize(m.Documentation), normalize(m.ToCodeString()))
						
	def normalize(s as string):
		return s.Trim().Replace("\r\n", "\n")
		
	def booRoundtripTestCasesPath():
		
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