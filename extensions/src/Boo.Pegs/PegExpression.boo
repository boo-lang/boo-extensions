namespace Boo.Pegs

abstract class PegExpression:
	abstract def Eval(context as PegContext) as bool:
		pass
	
class EmptyExpression(PegExpression):	
	override def Eval(context as PegContext):
		return true
		
class AnyExpression(PegExpression):
	override def Eval(context as PegContext):
		return context.Input.MoveNext()
		
class CharPredicateExpression(PegExpression):
	
	callable CharPredicate(c as char) as bool
	
	_predicate as CharPredicate
	
	def constructor(predicate as CharPredicate):
		_predicate = predicate
		
	override def Eval(context as PegContext):
		input = context.Input
		return input.MoveNext() and _predicate(input.CurrentChar)

class FunctionExpression(PegExpression):
	
	callable PegFunction(context as PegContext) as bool
	
	_function as PegFunction
	
	def constructor(function as PegFunction):
		_function = function
		
	override def Eval(context as PegContext):
		return _function(context) 
