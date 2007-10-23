namespace Boo.Adt.Tests

import NUnit.Framework
import Boo.Adt

[TestFixture]
class DataMacroTest:
	
	[Test]
	def TestClassHierarchy():
		type = Expression
		assert type.IsAbstract
		
		for type in Const, Add:
			assert not type.IsAbstract
			assert not type.IsSealed
			
	[Test]
	def TestToString():
		Assert.AreEqual("Const(42)", Const(42).ToString())
		Assert.AreEqual("Add(Const(19), Const(22))", Add(Const(19), Const(22)).ToString())
		
	[Test]
	def TestEquals():
		Assert.AreEqual(Const(42), Const(42))
		assert Const(-1) != Const(42)
		
	[Test]
	def TestProperties():
		Assert.AreEqual(42, Const(42).value)
	
	def DefineData():
		# TODO: parser needs to be changed to allow
		# macros at the top level
		data Expression = Const(value as int) \
			| Add(left as Expression, right as Expression)