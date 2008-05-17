namespace Boojay.Compilation

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem

class JavaTypeSystem(TypeSystemServices):
	
	def constructor(context as CompilerContext):
		super(context)
		self.StringType = ReplaceMapping(System.String, java.lang.String)
		AddPrimitiveType("string", self.StringType)
		
#		self.ExceptionType = ReplaceMapping(System.Exception, java.lang.RuntimeException)
		
	def ReplaceMapping(existing as System.Type, new as System.Type):
		mapping = Map(new)
		Cache(existing, mapping)
		return mapping
