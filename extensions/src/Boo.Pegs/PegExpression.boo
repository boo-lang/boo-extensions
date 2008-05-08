namespace Boo.Pegs

abstract class PegExpression:
	abstract def Match(context as PegContext) as bool:
		pass
	
class EmptyExpression(PegExpression):	
	override def Match(context as PegContext):
		return true
		
class AnyExpression(PegExpression):
	override def Match(context as PegContext):
		return context.Input.MoveNext()
		
class CharPredicateExpression(PegExpression):
	
	callable CharPredicate(c as char) as bool
	
	_predicate as CharPredicate
	
	def constructor(predicate as CharPredicate):
		_predicate = predicate
		
	override def Match(context as PegContext):
		input = context.Input
		if not input.MoveNext():
			return false
		if not _predicate(input.CurrentChar):
			if not context.InNotPredicate:
				input.MovePrevious()
			return false
		return true
		
class ActionExpression(PegExpression):
	
	_action as PegAction
	
	def constructor(action as PegAction):
		_action = action
		
	override def Match(ctx as PegContext):
		ctx.OnAction(_action)
		return true
		
class ZeroOrMany(PegExpression):
	
	_e as PegExpression
	
	def constructor(e as PegExpression):
		_e = e

	override def Match(ctx as PegContext):
		while ctx.Try(_e):
			pass
		return true

abstract class CompositeExpression(PegExpression):

	_expressions as (PegExpression)

	def constructor(expressions as (PegExpression)):
		_expressions = expressions
		
class SequenceExpression(CompositeExpression):
	
	def constructor(expressions as (PegExpression)):
		super(expressions)
		
	override def Match(ctx as PegContext):
		for e in _expressions:
			if not e.Match(ctx): return false
		return true
		
class ChoiceExpression(CompositeExpression):

	def constructor(expressions as (PegExpression)):
		super(expressions)
			
	override def Match(ctx as PegContext):
		for i in range(len(_expressions)-1):
			if ctx.Try(_expressions[i]):
				return true
		return ctx.Match(_expressions[-1])

class FunctionExpression(PegExpression):
	
	callable PegFunction(context as PegContext) as bool
	
	_function as PegFunction
	
	def constructor(function as PegFunction):
		_function = function
		
	override def Match(context as PegContext):
		return _function(context)