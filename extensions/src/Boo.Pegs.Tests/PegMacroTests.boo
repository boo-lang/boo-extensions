namespace Boo.Pegs.Tests

import NUnit.Framework
import Boo.Pegs

[TestFixture]
class PegMacroTests:
	
	[Test]
	def TestZeroOrMany():
		
		value = ""
		peg:
			zeroOrMany = --"foo", { value = $text }, eof
			eof = not any()
		
		for i in range(5):
			PegAssert.Matches("foo" * i, zeroOrMany)
			Assert.AreEqual("foo" * i, value)
			
	[Test]
	def TestOneOrMany():
		
		peg:
			oneOrMany = ++"foo", eof
			eof = not any()
		
		PegAssert.DoesNotMatch("", oneOrMany)
		for i in range(1, 5):
			PegAssert.Matches("foo" * 1, oneOrMany)
	
	[Test]
	def TestText():
		trace = []
		add = trace.Add
		peg:
			code = prefix, "a", { add($text) }, ++["a", "d"], { add($text) }
			prefix = { add($text) }, ++(digit(), { add($text) })
		
		PegAssert.Matches("42aad", code)
		Assert.AreEqual(["", "4", "42", "42a", "42aad"], trace)
	
	[Test]
	def TestActionOrdering():
		trace = []
		add = trace.Add
		peg:
			main = ++[foo, bar]
			foo = "foo", { add("foo") }, --("baz", { add("baz") })
			bar = "bar", { add("bar") }
			
		s = "foobarbarfoobazbar"
		ctx = PegAssert.Matches(s, main)
		Assert.AreEqual(["foo", "bar", "bar", "foo", "baz", "bar"], trace)
		Assert.AreEqual(s.Length, ctx.Input.Position)
		
