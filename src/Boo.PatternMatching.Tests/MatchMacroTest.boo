namespace Boo.PatternMatching.Tests

import NUnit.Framework
import Boo.PatternMatching
	
class Item:
	public static final Default = Item(Name: "default")
	
	[property(Name)] _name = ""
	[property(Child)] _child as Item
	
[TestFixture]
class MatchMacroTest:
	
	[Test]
	def TestPropertyPattern():
		Assert.AreEqual("item foo", itemByName(Item(Name: "foo")))
		Assert.AreEqual("not foo", itemByName(Item(Name: "not foo")))
		
	[Test]
	def TestNestedPropertyPattern():
		Assert.AreEqual("foo:bar", nestedByName(
								Item(Name: "foo",
									Child: Item(Name: "bar"))))

	[Test]
	def TestQualifiedReference():
		Assert.AreEqual("default item", itemByQualifiedReference(Item.Default))
		Assert.AreEqual("foo", itemByQualifiedReference(Item(Name: "foo")))
		
	[Test]
	def TestImplicitPropertyPattern():
		Assert.AreEqual("FOO", itemByImplicitNameReference(Item(Name: "foo")))
											
	[Test]
	[ExpectedException(MatchError)]
	def TestMatchErrorOnPropertyPattern():
		itemByName(42)
		
	[Test]
	def TestMatchErrorMessageIncludesValue():
		try:
			itemByName(42)
		except e as MatchError:
			Assert.AreEqual("'o' failed to match '42'", e.Message)
		
	[Test]
	[ExpectedException(MatchError)]
	def TestMatchErrorOnNestedPropertyPattern():
		nestedByName(42)
		
	[Test]
	def TestCaseCapture():
		Assert.AreEqual("foo", caseCapture(Item(Name: "foo")))
		Assert.AreEqual(42, caseCapture(21))
		
	enum Foo:
		None
		Bar
		Baz
		
	[Test]
	def TestMemberReferenceIsTreatedAsValueComparison():
		Assert.AreEqual("Bar", matchMemberRef(Foo.Bar))
		Assert.AreEqual("Bar", matchMemberRef(Foo.Baz))
		
	[Test]
	[ExpectedException(MatchError)]
	def TestMatchErrorOnMemberReferencePattern():
		matchMemberRef(Foo.None)

	def itemByName(o):
		match o:
			case Item(Name: "foo"):
				return "item foo"
			case Item(Name: name):
				return name
				
	def nestedByName(o):
		match o:
			case Item(Name: outer, Child: Item(Name: inner)):
				return "${outer}:${inner}"
				
	def itemByQualifiedReference(o):
		match o:
			case Item(Name: Item.Default.Name):
				return "default item"
			case Item(Name: name):
				return name
				
	def itemByImplicitNameReference(o):
		match o:
			case Item(Name):
				return Name.ToUpper()
				
	def caseCapture(o):
		match o:
			case i = int():
				return i*2
			case item = Item():
				return item.Name
				
	def matchMemberRef(o as Foo):
		match o:
			case Foo.Bar:
				return "Bar"
			case Foo.Baz:
				return "Baz"

	