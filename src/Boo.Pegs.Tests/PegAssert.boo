namespace Boo.Pegs.Tests

import Boo.Pegs
import NUnit.Framework

static class PegAssert:
	
	def NextChar(expected as string, context as PegContext):
		assert context.Input.MoveNext()
		Assert.AreEqual(expected[0], context.Input.CurrentChar)
		
	def Matches(text as string, e as PegExpression):
		return Matches(PegContext(text), e)
		
	def Matches(context as PegContext, e as PegExpression):
		input = context.Input
		assert e.Match(context), "Position: " + input.Position + ", Text: " + input.Text[input.Position:]
		return context
		
	def DoesNotMatch(text as string, e as PegExpression):
		assert not e.Match(PegContext(text))
		
	def DoesNotMatch(text as string, position as int, e as PegExpression):
		ctx = PegContext(text)
		assert not e.Match(ctx)
		Assert.AreEqual(position, ctx.Input.Position)
		
