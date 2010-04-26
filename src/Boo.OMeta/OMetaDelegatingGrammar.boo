namespace Boo.OMeta
		
class OMetaDelegatingGrammar(OMetaGrammarBase):
	
	_prototype as OMetaGrammar
	
	def constructor(prototype as OMetaGrammar):
		_prototype = prototype
		
	def Apply(rule as string, input as OMetaInput):
		return OMetaEvaluationContextImpl(self).Eval(rule, input)
		
	def Apply(rule as string, input as System.Collections.IEnumerable):
		return Apply(rule, OMetaInput.For(input))
		
	override def RuleMissing(context as OMetaEvaluationContext, rule as string, input as OMetaInput):
		return _prototype.Apply(context, rule, input)
		
	def SuperApply(context as OMetaEvaluationContext, rule as string, input as OMetaInput):
		return _prototype.Apply(context, rule, input)
