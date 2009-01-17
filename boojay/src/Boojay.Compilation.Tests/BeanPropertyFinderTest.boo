namespace Boojay.Compilation.Tests

import NUnit.Framework

import Boo.Lang.Compiler.TypeSystem
import Boojay.Compilation.TypeSystem

[TestFixture]
class BeanPropertyFinderTest:
			
	[Test] def SimpleProperty():
		p = expectingSingleBeanPropertyWithNameAndTypeOn(ClassWithSimpleProperty, "name", string)
		Assert.AreEqual("getName", p.GetGetMethod().Name)
		Assert.AreEqual("setName", p.GetSetMethod().Name)
		
	[Test] def ReadOnlyProperty():
		p = expectingSingleBeanPropertyWithNameAndTypeOn(ClassWithReadOnlyProperty, "value", int)
		assert p.GetSetMethod() is null
		Assert.AreEqual("getValue", p.GetGetMethod().Name)
		
	[Test] def WriteOnlyProperty():
		p = expectingSingleBeanPropertyWithNameAndTypeOn(ClassWithWriteOnlyProperty, "value", object)
		assert p.GetGetMethod() is null
		Assert.AreEqual("setValue", p.GetSetMethod().Name)
		
	[Test] def IndexedProperty():
		pass
		
	[Test] def OverloadedIndexedProperty():
		pass
		
	[Test] def ConflictingSetters():
		properties = beanPropertiesFor(ClassWithConflictingSetters)
		assert 0 == len(properties), join(properties, ", ")
		
	class ClassWithSimpleProperty:
		def getName() as string:
			pass
		def setName(value as string):
			pass
			
	class ClassWithReadOnlyProperty:
		def getValue():
			return 0
			
	class ClassWithWriteOnlyProperty:
		def setValue(value):
			pass
			
	class ClassWithConflictingSetters:
		def setValue(value as int):
			pass
		def setValue(vaue as string):
			pass
		
	def expectingSingleBeanPropertyWithNameAndTypeOn(type as System.Type, expectedName as string, expectedType as System.Type):
		p = expectingSingleBeanPropertyFor(type)
		assertPropertyNameAndType p, expectedName, expectedType
		return p
		
	def expectingSingleBeanPropertyFor(type as System.Type):
		properties = beanPropertiesFor(type)
		assert 1 == len(properties), join(properties, ", ")
		return properties[0]
		
	def assertPropertyNameAndType(p as IProperty, expectedName as string, expectedType as System.Type):
		Assert.AreEqual(expectedName, p.Name)
		Assert.AreSame(bindingFor(expectedType), p.Type)
	
	typeSystem = JavaTypeSystem()
		
	def beanPropertiesFor(type as System.Type):
		return array(BeanPropertyFinder(bindingFor(type).GetMembers()).findAll())
		
	def bindingFor(type as System.Type):
		return typeSystem.Map(type)
