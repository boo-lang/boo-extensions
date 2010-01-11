namespace Boo.MonoDevelop.ProjectModel

import System
import System.CodeDom.Compiler

class BooCodeDomProvider(CodeDomProvider):
	
	override FileExtension:
		get: return "boo"
		
	override def CreateCompiler():		
		raise NotImplementedException()
		
	override def CreateGenerator():
		print "creating generator..."	
		return BooCodeGenerator()
		
	override def GetConverter(type as Type) as System.ComponentModel.TypeConverter:
		raise NotImplementedException()
		
