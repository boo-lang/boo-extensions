namespace Boo.Adt.Tests

import NUnit.Framework
import Boo.Adt

data Expression = Const(value as int) \
			| Add(left as Expression, right)
			
data ExpressionX < Expression = Mult(left as Expression, right as Expression)

data Result(Value as int) = Success() | Failure(Error as string)

data Foo(Value as int)

#data Bar(Value as int, Count as int) < Foo(Value)

data Struct(Value as int) < System.ValueType

[TestFixture]
class DataMacroTest:
	
	[Test]
	def ValueTypeBaseType():
		assert typeof(Struct).IsValueType
	
	[Test]
	def Member():
		data WithMember(Foo):
			public final Bar = "bar"
		Assert.AreEqual("bar", WithMember("foo").Bar)
	
	[Test]
	def OmittedFieldTypeDefaultsToDataType():
		for parameter in typeof(Add).GetConstructors()[0].GetParameters():
			assert Expression is parameter.ParameterType 
	
	[Test]
	def TestMutableField():
		data Mutable(@m as int, i as int)
		
		assert not typeof(Mutable).GetField("m").IsInitOnly
		assert typeof(Mutable).GetField("i").IsInitOnly
	
	[Test]
	def TestSingleType():
		type = Foo
		assert object is type.BaseType
		Assert.AreEqual("Foo(42)", Foo(42).ToString())

	[Test]
	def TestBaseFields():
		Assert.AreEqual("Success(42)", Success(42).ToString())
		Assert.AreEqual("Failure(42, crash)", Failure(42, "crash").ToString())
		Assert.AreEqual(Success(42), Success(42))
		Assert.IsFalse(Success(42) == Success(21))

	[Test]
	def TestClassHierarchy():
		type = Expression
		assert type.IsAbstract
		
		for type in Const, Add:
			assert not type.IsAbstract
			assert not type.IsSealed
			assert Expression is type.BaseType
			
		assert Expression is typeof(ExpressionX).BaseType
		assert ExpressionX is typeof(Mult).BaseType
			
	[Test]
	def TestToString():
		Assert.AreEqual("Const(42)", Const(42).ToString())
		Assert.AreEqual("Add(Const(19), Const(22))", Add(Const(19), Const(22)).ToString())
		Assert.AreEqual("Add(null, null)", Add(null, null).ToString())
		
	[Test]
	def ToStringUsesBracketsForArrays():
		data A = B() | C(*As)
		Assert.AreEqual("C([B(), C([])])", C(B(), C()).ToString())
		
	[Test]
	def OmittedArrayTypeDefaultsToArrayOfDataType():
		assert typeof((A)) is typeof(C).GetConstructors()[0].GetParameters()[0].ParameterType
		
	[Test]
	def TestEquals():
		Assert.AreEqual(Const(42), Const(42))
		assert Const(-1) != Const(42)
		
	[Test]
	def TestEqualsWithoutFields():
		data NoFields()
		Assert.AreEqual(NoFields(), NoFields())
		
	[Test]
	def TestProperties():
		Assert.AreEqual(42, Const(42).value)
		
	[Test]
	def OptionalArguments():
		data OptArgs(A, B = "foo", C as string = "bar")
		Assert.AreEqual(OptArgs("A", "foo", "bar"), OptArgs("A"))
		Assert.AreEqual(OptArgs("A", "B", "bar"), OptArgs("A", "B"))
		Assert.AreEqual(OptArgs("A", "B", "C"), OptArgs("A", "B", "C"))
		