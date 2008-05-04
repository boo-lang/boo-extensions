namespace Boo.Pegs

def empty():
	return EmptyExpression()
	
def any():
	return AnyExpression()
	
def action(action as PegAction):
	return ActionExpression(action)

def terminal(text as string):
	s = array(CharPredicateExpression({ current as char | current == ch }) for ch in text)
	return sequence(*s)
	
def sequence(*expressions as (PegExpression)):
	if 1 == len(expressions): return expressions[0]
	return SequenceExpression(expressions)
	
def choice(*expressions as (PegExpression)):
	if 1 == len(expressions): return expressions[0]
	return ChoiceExpression(expressions) 
	
def one_or_many(e as PegExpression):
	return sequence(e, ZeroOrMany(e))
		
def zero_or_many(e as PegExpression):
	return ZeroOrMany(e)

def not_predicate(e as PegExpression):
	ne = FunctionExpression() do (ctx as PegContext):
		return not ctx.Match(e)
	return FunctionExpression() do (ctx as PegContext):
		return ctx.TestNot(ne)
	
def char_range(begin as char, end as char):
	return CharPredicateExpression() do (current as char):
		return current >= begin and current <= end
		
def digit():
	return CharPredicateExpression(char.IsDigit)
	
def whitespace():
	return CharPredicateExpression(char.IsWhiteSpace)
