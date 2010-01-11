namespace Boo.MonoDevelop.Tests

import NUnit.Framework
import MonoDevelop.Projects
import MonoDevelop.Projects.Dom

[TestFixture]
class BooParserTest(UnitTests.TestBase):

	[Test]
	def SingleTypeModule():
	
		code = """namespace BooParserTest
class Foo:
	def Bar():
		pass
"""

		project as DotNetProject = CreateSingleFileProject("BooParserTest", code)
		dom = GetProjectDom(project)
		
		foo = dom.GetType("BooParserTest.Foo")
		assert foo is not null
		
		methods = List[of IMethod](foo.Methods)
		assert 1 == len(methods)
		Assert.AreEqual("Bar", methods[0].Name)
		Assert.AreEqual("void", methods[0].ReturnType.Name)
