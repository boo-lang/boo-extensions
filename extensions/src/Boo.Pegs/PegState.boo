namespace Boo.Pegs

import System

class ActionList:
	
	public static final Empty = ActionList()
	
	def Add(action as PegAction):
		return NonEmptyActionList(action, self)
		
	virtual def Execute(ctx as PegContext):
		pass
		
class NonEmptyActionList(ActionList):
	
	_action as PegAction
	_tail as ActionList
	
	def constructor(action as PegAction, tail as ActionList):
		_action = action
		_tail = tail
		
	override def Execute(ctx as PegContext):
		_tail.Execute(ctx)
		_action(ctx)

class PegTransaction:
	
	[getter(Context)]
	_context as PegContext
	
	def constructor(context as PegContext):
		_context = context
		
	virtual CanBacktrack:
		get: return false
		
	virtual def BeginNested() as PegTransaction:
		return TopLevel(_context)
		
	virtual def Commit():
		raise InvalidOperationException()
		
	virtual def Rollback():
		raise InvalidOperationException()
		
	virtual def OnAction(action as PegAction):
		action(Context)

class StateTransaction(PegTransaction):
	
	_state as (int)
	
	def constructor(context as PegContext):
		super(context)
		_state = context.GetMemento()
		
	override CanBacktrack:
		get: return true
		
	override def Commit():
		pass
		
	override def Rollback():
		Context.Restore(_state)
		
class TestTransaction(StateTransaction):
	
	def constructor(context as PegContext):
		super(context)
		
	override def BeginNested():
		return TestTransaction(Context)
		
	override def OnAction(_ as PegAction):
		pass
	
class TopLevel(StateTransaction):
		
	_action = ActionList.Empty
	
	def constructor(context as PegContext):
		super(context)
	
	override def BeginNested():
		return Nested(self)
		
	override def Commit():
		_action.Execute(Context)
		
	override def OnAction(action as PegAction):
		_action = _action.Add(contextful(action))
		
	def contextful(action as PegAction) as PegAction:
		memento = _context.GetMemento()
		return do (context as PegContext):
			context.WithMemento(memento, action)
			
class Nested(TopLevel):
	
	_parent as PegTransaction
	
	def constructor(parent as PegTransaction):
		super(parent.Context)
		_parent = parent
		
	override def Commit():
		_parent.OnAction(_action.Execute)
