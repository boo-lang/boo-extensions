namespace Boo.Pegs

class PegRule(PegExpression):
	
	[property(Expression)]
	_e as PegExpression
	
	override def Match(context as PegContext):
		return context.MatchRule(self)