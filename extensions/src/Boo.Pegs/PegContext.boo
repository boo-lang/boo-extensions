namespace Boo.Pegs

callable PegAction(context as PegContext)

class PegContext:
	
	[getter(Input)]
	_input as StringMarkResetEnumerator
	
	_transaction = PegTransaction(self)
	
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
		return WithTransaction(_transaction.BeginNested(), e)
		
	def Test(e as PegExpression):
		return WithTransaction(TestTransaction(self), e)
		
	CanBacktrack:
		get: return _transaction.CanBacktrack

	def WithTransaction(transaction as PegTransaction, e as PegExpression):
		old = _transaction
		_transaction = transaction
		try:
			if e.Match(self):
				_transaction.Commit()
				return true
			else:
				_transaction.Rollback()
				return false		
		ensure:
			_transaction = old
						
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
		_transaction.OnAction(action)
				
	def EnterRule():
		_ruleMarker = _input.Mark()
		
def text(ctx as PegContext):
	return ctx.Input.TextFrom(ctx.EnterRuleMarker)