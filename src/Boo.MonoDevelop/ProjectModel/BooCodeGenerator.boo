namespace Boo.MonoDevelop.ProjectModel

import System.CodeDom.Compiler

class BooCodeGenerator(CodeGenerator):
	
	NullToken:
		get: return "null"
	
	override def Supports(supports as GeneratorSupport):
		return false
		
	override def CreateEscapedIdentifier(value as string):
		return value
		
	override def CreateValidIdentifier(value as string):
		return value