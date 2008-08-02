namespace Boo.OMeta
		
class OMetaDelegatingGrammar(OMetaGrammarLR):
	
	_prototype as OMetaGrammar
	
	def constructor(prototype as OMetaGrammar):
		_prototype = prototype
		
	override def RuleMissing(context as OMetaGrammar, rule as string, input as OMetaInput):
		return _prototype.Eval(context, rule, input)
		
	override def SuperApply(context as OMetaGrammar, rule as string, input as OMetaInput):
		return _prototype.Eval(context, rule, input)
		

