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
			if not context.CanBacktrack:
				input.MovePrevious()
			return false
		return true

class FunctionExpression(PegExpression):
	
	callable PegFunction(context as PegContext) as bool
	
	_function as PegFunction
	
	def constructor(function as PegFunction):
		_function = function
		
	override def Match(context as PegContext):
		return _function(context) 
