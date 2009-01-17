namespace Boojay.Compilation.Tests

import NUnit.Framework

import Boo.Lang.Compiler.TypeSystem
import Boojay.Compilation.TypeSystem

[TestFixture]
class JavaTypeSystemTest:
	
	class Bean:
		def getName() as string:
			pass
		def setName(value as string):
			pass
	
	typeSystem = JavaTypeSystem()
	
	[Test] def BeanProperties():
		
		members = typeSystem.Map(Bean).GetMembers()
		System.Array.Sort(members, { l as IEntity, r as IEntity | l.Name.CompareTo(r.Name) })
		
		Assert.AreEqual("constructor, getName, name, setName", join(member.Name for member in members, ", "))
		