namespace Boojay.Compilation.Tests

import NUnit.Framework
import Boo.Lang.Parser
import Boo.Lang.Compiler
import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.Ast
import Boojay.Compilation

[TestFixture]
partial class IntegrationTestFixture:
	
	def runTestCase(fname as string):
		unit = parse(fname)	
		main = unit.Modules[0]
		compile(unit)
		output = runJavaClass(moduleClassFor(main))
		Assert.IsNotNull(main.Documentation, "Expecting documentation for '${fname}'")
		Assert.AreEqual(normalizeWhiteSpace(main.Documentation), normalizeWhiteSpace(output))
		
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
