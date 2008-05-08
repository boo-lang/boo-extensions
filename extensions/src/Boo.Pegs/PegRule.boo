namespace Boo.Pegs

class PegRule(PegExpression):
	
	[property(Expression)]
	_e as PegExpression
	
	[property(Name)]
	_name as string
	
	def constructor(name as string):
		_name = name
	
	override def Match(context as PegContext):
		return context.MatchRule(self)
		
	override def ToString():
		return _name;