namespace Boo.Pegs.Tests

import Boo.Pegs
import NUnit.Framework

[TestFixture]
class PegTests:
	
	[Test]
	def TestActionOrdering():
		trace = []
		peg:
			main = ++[foo, bar]
			foo = "foo", { trace.Add("foo") }, --({ trace.Add("baz") }, "baz")
			bar = "bar", { trace.Add("bar") }
			
		assertMatch("foobarbarfoobazbar", main)
		Assert.AreEqual(["foo", "bar", "bar", "foo", "baz", "bar"], trace)
	
	[Test]
	def TestTerminal():
		e = terminal("foo")
		context = assertMatch("foo", e)
		assert not context.Input.MoveNext()
		
		context = assertMatch("foo\t", e)
		assertNextChar "\t", context
		
	[Test]
	def TestRepetition():
		e = repetition(terminal("foo"))
		assertMatch "foo", e
		context = assertMatch("foofoobar", e)
		assertNextChar "b", context
		
	[Test]
	def TestSequence():
		e = sequence(terminal("foo"), terminal("bar"))
		context = assertMatch("foobar\t", e)
		assertNextChar "\t", context
		
	[Test]
	def TestChoice():
		e = choice(terminal("foo"), terminal("bar"))
		context = assertMatch("foobar", e)
		mark = context.Input.Mark()
		assertNextChar "b", context
		context.Input.Reset(mark)
		assertMatch context, e
		
	[Test]
	def TestNegation():
		e = negation(terminal("o"))
		context = assertMatch("aeioou", e)
		assertNextChar "e", context
		assertMatch context, e
		assertNextChar "o", context
		assert not e.Eval(context)
		assertNextChar "o", context
		
	def assertNextChar(expected as string, context as PegContext):
		assert context.Input.MoveNext()
		Assert.AreEqual(expected[0], context.Input.CurrentChar)
		
	def assertMatch(text as string, e as PegExpression):
		return assertMatch(PegContext(text), e)
		
	def assertMatch(context as PegContext, e as PegExpression):
		assert e.Eval(context)
		return context