namespace Boo.Pegs

class PegRule(PegExpression):
	
	[property(expression)]
	_e as PegExpression
	
	override def Eval(context as PegContext):
		context.EnterRule()
		return _e.Eval(context)