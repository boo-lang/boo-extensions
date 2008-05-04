namespace Boo.Pegs

def empty():
	return EmptyExpression()
	
def any():
	return AnyExpression()
	
def action(action as PegAction):
	return FunctionExpression() do (ctx as PegContext):
		ctx.OnAction(action)
		return true

def terminal(text as string):
	s = array(CharPredicateExpression({ current as char | current == ch }) for ch in text)
	return sequence(*s)
	
def sequence(*expressions as (PegExpression)):
	return FunctionExpression() do (ctx as PegContext):
		for e in expressions:
			if not ctx.Match(e): return false
		return true
	
def choice(*expressions as (PegExpression)):
	return FunctionExpression() do (ctx as PegContext):
		for i in range(len(expressions)-1):
			if ctx.Try(expressions[i]):
				return true
		return ctx.Match(expressions[-1])
	
def repetition(e as PegExpression):
	return FunctionExpression() do (ctx as PegContext):
		if ctx.Match(e):
			while ctx.Match(e):
				pass
			return true
		return false
		
def zero_or_many(e as PegExpression):
	return FunctionExpression() do (ctx as PegContext):
		while ctx.Match(e):
			pass
		return true

def negation(e as PegExpression):
	ne = FunctionExpression() do (ctx as PegContext):
		return not ctx.Match(e)
	return FunctionExpression() do (ctx as PegContext):
		return ctx.Test(ne)
	
def char_range(begin as char, end as char):
	return CharPredicateExpression() do (current as char):
		return current >= begin and current <= end
		
def digit():
	return CharPredicateExpression(char.IsDigit)
	
def whitespace():
	return CharPredicateExpression(char.IsWhiteSpace)
