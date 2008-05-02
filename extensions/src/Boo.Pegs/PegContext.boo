namespace Boo.Pegs

callable PegAction(context as PegContext)

class PegContext:
	
	_input as StringMarkResetEnumerator
	
	_transaction = PegTransaction(self)

	def constructor(text as string):
		_input = StringMarkResetEnumerator(text)
	
	Input as StringMarkResetEnumerator:
		get: return _input
		
	def Try(e as PegExpression):
		old = _transaction
		_transaction = _transaction.BeginNested()
		try:
			if e.Eval(self):
				_transaction.Commit()
				return true
			else:
				_transaction.Rollback()
				return false		
		ensure:
			_transaction = old
		
	def OnAction(action as PegAction):
		_transaction.OnAction(action)
		
def text(ctx as PegContext):
	return "42"