namespace Boo.Adt.Tests

import NUnit.Framework
import Boo.Adt

[TestFixture]
class GenericDataMacroTest:
	
	[Test]
	def TestClassHierarchy():
		type = GExpression[of int]
		assert type.IsAbstract
		
		for type in GConst[of int], GAdd[of int]:
			assert not type.IsAbstract
			assert not type.IsSealed
			
	[Test]
	def TestToString():
		Assert.AreEqual("GConst(42)", GConst[of int](42).ToString())
		Assert.AreEqual("GAdd(GConst(19), GConst(22))", GAdd[of int](GConst[of int](19), GConst[of int](22)).ToString())

	[Test]
	def TestEquals():
		Assert.AreEqual(GConst[of int](42), GConst[of int](42))
		assert GConst[of int](-1) != GConst[of int](42)
		
	[Test]
	def TestProperties():
		Assert.AreEqual(42, GConst[of int](42).value)
	
	def DefineData():
		data GExpression[T] = GConst(value as T) \
			| GAdd(left as GExpression[T], right as GExpression[T])