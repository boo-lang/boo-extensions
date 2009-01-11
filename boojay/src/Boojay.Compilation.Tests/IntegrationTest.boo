namespace Boojay.Compilation.Tests

import System.IO

import NUnit.Framework

import Boo.Lang.Parser
import Boo.Lang.Compiler
import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.Ast
import Boojay.Compilation

[TestFixture]
partial class IntegrationTest:
	
	def runTestCase(testFile as string):
		unit = parse(fullpathFor(testFile))	
		main = unit.Modules[0]
		compile(unit)
		output = runJavaClass(moduleClassFor(main))
		Assert.IsNotNull(main.Documentation, "Expecting documentation for '${testFile}'")
		Assert.AreEqual(normalizeWhiteSpace(main.Documentation), normalizeWhiteSpace(output))
		
	def fullpathFor(testFile as string):
		eclipseBuildPath = Path.Combine("../boojay", testFile)
		return eclipseBuildPath if File.Exists(eclipseBuildPath)
		
		return Path.Combine("..", testFile)
		
	def normalizeWhiteSpace(s as string):
		return s.Trim().Replace("\r\n", "\n")
		
	def compile(unit as CompileUnit):
		compiler = newBoojayCompiler()
		result = compiler.Run(unit)
		assert 0 == len(result.Errors), result.Errors.ToString(true) + unit.ToCodeString()
			
	def parse(fname as string):
		return BooParser.ParseFile(System.IO.Path.GetFullPath(fname))
		
	def moduleClassFor(module as Module):
		return module.FullName + "Module"
		
	def runJavaClass(className as string):
		p = shellp("java", "-cp . ${className}")
		p.WaitForExit()
		if p.ExitCode != 0: raise p.StandardError.ReadToEnd()
		return p.StandardOutput.ReadToEnd()
