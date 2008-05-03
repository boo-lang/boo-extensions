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
		assert e.Eval(context)
		return context
		
	def DoesNotMatch(text as string, e as PegExpression):
		assert not e.Eval(PegContext(text))
