namespace Boo.Pegs

def empty():
	return EmptyExpression()
	
def any():
	return AnyExpression()
	
def action(action as PegAction):
	return FunctionExpression() do (context as PegContext):
		context.OnAction(action)
		return true

def terminal(text as string):
	return FunctionExpression() do (context as PegContext):
		input = context.Input
		for ch in text:
			if not input.MoveNext() or ch != input.CurrentChar:
				return false
		return true
	
def sequence(*expressions as (PegExpression)):
	return FunctionExpression() do (context as PegContext):
		for e in expressions:
			if not e.Eval(context): return false
		return true
	
def choice(*expressions as (PegExpression)):
	return FunctionExpression() do (context as PegContext):
		for e in expressions:
			if context.Try(e):
				return true
		return false
	
def repetition(e as PegExpression):
	return FunctionExpression() do (context as PegContext):
		if not e.Eval(context): return false
		while context.Try(e):
			pass
		return true

def negation(e as PegExpression):
	ne = FunctionExpression() do (context as PegContext):
		return not e.Eval(context)
	return FunctionExpression() do (context as PegContext):
		return context.Try(ne)
	
def charRange(begin as char, end as char):
	return CharPredicateExpression() do (current as char):
		return current >= begin and current <= end
		
def digit():
	return CharPredicateExpression(char.IsDigit)
	
def whitespace():
	return CharPredicateExpression(char.IsWhiteSpace)
