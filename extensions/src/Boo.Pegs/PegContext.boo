namespace Boo.Pegs

callable PegAction(context as PegContext)

class PegContext:
	
	[getter(Input)]
	_input as StringMarkResetEnumerator
	
	_state = PegState(self)
	
	[getter(EnterRuleMarker)]
	_ruleMarker = -1

	def constructor(text as string):
		_input = StringMarkResetEnumerator(text)
		
	def Match(e as PegExpression):
		return e.Match(self)
		
	def MatchRule(rule as PegRule):
		EnterRule()
		return Match(rule.Expression)
		
	def Try(e as PegExpression):
		return WithState(_state.BeginChoice(), e)
		
	def TestNot(e as PegExpression):
		return WithState(NotPredicateState(self), e)
		
	InNotPredicate:
		get: return _state.InNotPredicate

	def WithState(state as PegState, e as PegExpression):
		old = _state
		_state = state
		try:
			if e.Match(self):
				_state.Commit()
				return true
			else:
				_state.Rollback()
				return false		
		ensure:
			_state = old
						
	def GetMemento():
		return (_ruleMarker, _input.Mark())
		
	def WithMemento(memento as (int), action as PegAction):
		saved = GetMemento()
		Restore(memento)
		try:
			action(self)
		ensure:
			Restore(saved)
			
	def Restore(memento as (int)):
		ruleMarker, inputMarker = memento
		_ruleMarker = ruleMarker
		_input.Reset(inputMarker)
		
	def OnAction(action as PegAction):
		_state.OnAction(action)
				
	def EnterRule():
		_ruleMarker = _input.Mark()
		
def text(ctx as PegContext):
	return ctx.Input.TextFrom(ctx.EnterRuleMarker)