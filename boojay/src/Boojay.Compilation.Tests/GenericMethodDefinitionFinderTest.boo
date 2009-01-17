namespace Boojay.Compilation.Tests

import NUnit.Framework
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boojay.Compilation.TypeSystem

class GenericFoo[of T]:
	def Bar(value as T):
		return value

[TestFixture]
class GenericMethodDefinitionFinderTest:
	
	_typeSystem = TypeSystemServices(CompilerContext(CompileUnit()))
	
	[Test]
	def FindGenericMethod():
		
		method = _typeSystem.Map(typeof(GenericFoo[of int]).GetMethod("Bar"))
		
		found = GenericMethodDefinitionFinder(method).find()
		Assert.AreSame(_typeSystem.Map(typeof(GenericFoo of *).GetMethod("Bar")), found)
		