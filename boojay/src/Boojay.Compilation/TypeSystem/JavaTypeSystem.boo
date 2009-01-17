namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem

class JavaTypeSystem(TypeSystemServices):
	
	def constructor():
		self(CompilerContext())
	
	def constructor(context as CompilerContext):
		super(context)
		self.StringType = ReplaceMapping(System.String, JavaLangString)
		self.AddPrimitiveType("string", self.StringType)
		self.MulticastDelegateType = ReplaceMapping(System.MulticastDelegate, Boojay.Lang.MulticastDelegate)
		self.ListType = ReplaceMapping(Boo.Lang.List, Boojay.Lang.List)
		self.HashType = ReplaceMapping(Boo.Lang.Hash, Boojay.Lang.Hash)
		
	override def CreateEntityForRegularType(type as System.Type):
		return BeanAwareType(self, type)
		
	override ExceptionType:
		get: return Map(java.lang.Exception)
	
	def ReplaceMapping(existing as System.Type, new as System.Type):
		mapping = Map(new)
		Cache(existing, mapping)
		return mapping
		
class JavaLangString(System.Collections.IEnumerable):

	self[index as int] as char:
		get: return char.MinValue
	
	Length:
		get: return 0
	
	def GetEnumerator():
		return null
		
	def toUpperCase():
		return self
		
	def toLowerCase():
		return self
		
	def trim():
		return self
		
	def toCharArray() as (char):
		return null
