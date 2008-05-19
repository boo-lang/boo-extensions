namespace Boojay.Compilation

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem

class JavaTypeSystem(TypeSystemServices):
	
	def constructor(context as CompilerContext):
		super(context)
		
	override ExceptionType:
		get: return Map(java.lang.Exception)
	
	def ReplaceMapping(existing as System.Type, new as System.Type):
		mapping = Map(new)
		Cache(existing, mapping)
		return mapping
