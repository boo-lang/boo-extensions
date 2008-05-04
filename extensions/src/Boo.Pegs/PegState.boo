namespace Boo.Pegs

import System

class ActionList:
	
	public static final Empty = ActionList()
	
	def Add(action as PegAction):
		return NonEmptyActionList(action, self)
		
	virtual def Execute(ctx as PegContext):
		pass
		
	virtual IsEmpty:
		get: return true
		
class NonEmptyActionList(ActionList):
	
	_action as PegAction
	_tail as ActionList
	
	def constructor(action as PegAction, tail as ActionList):
		_action = action
		_tail = tail
		
	override def Execute(ctx as PegContext):
		_tail.Execute(ctx)
		_action(ctx)
		
	override IsEmpty:
		get: return false

class PegState:
	
	[getter(Context)]
	_ctx as PegContext
	
	def constructor(ctx as PegContext):
		_ctx = ctx
		
	virtual InNotPredicate:
		get: return false
		
	virtual def BeginChoice() as PegState:
		return TopLevelChoice(_ctx)
		
	virtual def Commit():
		raise InvalidOperationException()
		
	virtual def Rollback():
		raise InvalidOperationException()
		
	virtual def OnAction(action as PegAction):
		action(Context)

class AbstractChoiceState(PegState):
	
	_state as (int)
	
	def constructor(ctx as PegContext):
		super(ctx)
		_state = ctx.GetMemento()
		
	override def Commit():
		pass
		
	override def Rollback():
		Context.Restore(_state)
		
class NotPredicateState(AbstractChoiceState):
	
	def constructor(ctx as PegContext):
		super(ctx)
		
	override InNotPredicate:
		get: return true

	override def BeginChoice():
		return NotPredicateState(Context)
		
	override def OnAction(_ as PegAction):
		pass
	
class TopLevelChoice(AbstractChoiceState):
		
	_action = ActionList.Empty
	
	def constructor(ctx as PegContext):
		super(ctx)
	
	override def BeginChoice():
		return NestedChoice(self)
		
	override def Commit():
		_action.Execute(Context)
		
	override def OnAction(action as PegAction):
		_action = _action.Add(contextful(action))
		
	def contextful(action as PegAction) as PegAction:
		memento = _ctx.GetMemento()
		return do (ctx as PegContext):
			ctx.WithMemento(memento, action)
			
class NestedChoice(TopLevelChoice):
	
	_parent as PegState
	
	def constructor(parent as PegState):
		super(parent.Context)
		_parent = parent
		
	override def Commit():
		if _action.IsEmpty: return
		_parent.OnAction(_action.Execute)
