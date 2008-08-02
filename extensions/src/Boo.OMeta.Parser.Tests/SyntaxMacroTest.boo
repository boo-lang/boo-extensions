namespace Boo.OMeta.Parser.Tests

import Boo.OMeta
import Boo.OMeta.Parser
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import NUnit.Framework

syntax Units:
	atom = mass | super
	mass = (integer >> value, "kg") ^ [| Mass($(value as Expression), "kg") |]

[TestFixture]
class SyntaxMacroTest:
	
	[Test]
	def AssemblyAttributeIsIntroducedByMacro():
		
		attributes = GetType().Assembly.GetCustomAttributes(SyntaxExtensionAttribute, false)
		Assert.AreEqual(1, len(attributes))
		
		extension as SyntaxExtensionAttribute = attributes[0]
		Assert.AreSame(Units, extension.Type)
		
	[Test]
	def ImportCausesExtensionToBeAvailable():
		
		code = """
import Boo.OMeta.Parser.Tests.Units

a = 3kg
print(a)
"""
		
		result = parse(code)
		assert 0 == len(result.Errors), result.Errors.ToString()
	
		expected = [|
			import Boo.OMeta.Parser.Tests.Units
			
			a = Mass(3, "kg")
			print(a)
		|]
		Assert.AreEqual(1, len(result.CompileUnit.Modules))
		Assert.AreEqual(expected.ToCodeString(), result.CompileUnit.Modules[0].ToCodeString())
		
	def parse(code as string):
		compiler = BooCompiler()
		compiler.Parameters.References.Add(GetType().Assembly)
		compiler.Parameters.Input.Add(IO.StringInput("code", code))
		compiler.Parameters.Pipeline = CompilerPipeline()
		compiler.Parameters.Pipeline.Add(BooParserStep())
		result = compiler.Run()
		return result
		
		