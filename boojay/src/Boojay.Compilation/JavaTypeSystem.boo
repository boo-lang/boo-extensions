namespace Boojay.Compilation

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem

class JavaTypeSystem(TypeSystemServices):
	
	def constructor(context as CompilerContext):
		super(context)
		self.StringType = ReplaceMapping(System.String, JavaLangString)
		self.AddPrimitiveType("string", self.StringType)
		
	override ExceptionType:
		get: return Map(java.lang.Exception)
	
	def ReplaceMapping(existing as System.Type, new as System.Type):
		mapping = Map(new)
		Cache(existing, mapping)
		return mapping
		
class JavaLangString:
	def toUpperCase():
		return self
		
	def toLowerCase():
		return self
