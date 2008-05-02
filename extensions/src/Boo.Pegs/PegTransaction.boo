namespace Boo.Pegs

import System

class PegTransaction:
	
	[getter(Context)]
	_context as PegContext
	
	def constructor(context as PegContext):
		_context = context
		
	virtual def BeginNested() as PegTransaction:
		return TopLevel(_context)
		
	virtual def Commit():
		pass
		
	virtual def Rollback():
		pass
		
	virtual def OnAction(action as PegAction):
		action(Context)
		
class TopLevel(PegTransaction):
		
	_action as PegAction = { ctx as PegContext | return }
	_inputMark as int
	
	def constructor(context as PegContext):
		super(context)
		_inputMark = context.Input.Mark()
	
	override def BeginNested():
		return Nested(self)
		
	override def Commit():
		_action(Context)
		
	override def Rollback():
		Context.Input.Reset(_inputMark)
		
	override def OnAction(action as PegAction):
		_action = System.Delegate.Combine(_action, action)
			
class Nested(TopLevel):
	
	_parent as PegTransaction
	
	def constructor(parent as PegTransaction):
		super(parent.Context)
		_parent = parent
		
	override def Commit():
		_parent.OnAction(_action)
