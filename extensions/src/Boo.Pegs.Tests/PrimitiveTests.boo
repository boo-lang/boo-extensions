namespace Boo.Pegs.Tests

import Boo.Pegs
import NUnit.Framework

[TestFixture]
class PrimitiveTests:
	
	[Test]
	def TestTerminal():
		e = terminal("foo")
		context = PegAssert.Matches("foo", e)
		assert not context.Input.MoveNext()
		
		context = PegAssert.Matches("foo\t", e)
		PegAssert.NextChar("\t", context)
		
	[Test]
	def TestRepetition():
		e = repetition(terminal("foo"))
		PegAssert.Matches("foo", e)
		context = PegAssert.Matches("foofoobar", e)
		PegAssert.NextChar("b", context)
		
	[Test]
	def TestSequence():
		e = sequence(terminal("foo"), terminal("bar"))
		context = PegAssert.Matches("foobar\t", e)
		PegAssert.NextChar("\t", context)
		
	[Test]
	def TestChoice():
		e = choice(terminal("foo"), terminal("bar"))
		context = PegAssert.Matches("foobar", e)
		mark = context.Input.Mark()
		PegAssert.NextChar("b", context)
		context.Input.Reset(mark)
		PegAssert.Matches(context, e)
		
	[Test]
	def TestNegation():
		e = negation(terminal("o"))
		context = PegAssert.Matches("aeioou", e)
		PegAssert.NextChar("e", context)
		PegAssert.Matches(context, e)
		PegAssert.NextChar("o", context)
		assert not e.Eval(context)
		PegAssert.NextChar("o", context)
