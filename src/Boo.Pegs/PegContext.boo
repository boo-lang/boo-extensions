namespace Boo.Pegs

callable PegAction(context as PegContext)

class PegContext:
	
	[getter(Input)]
	_input as StringMarkResetEnumerator
	
	_state = PegState(self)

	[getter(RuleState)]
	_ruleState = PegRuleState(self)

	def constructor(text as string):
		_input = StringMarkResetEnumerator(text)
		
	def Match(e as PegExpression):
		return e.Match(self)
		
	def MatchRule(rule as PegRule):
		_ruleState = EnterRule(rule)
		try:
			success = Match(rule.Expression)
		ensure:
			_ruleState = LeaveRule(rule, success)
		return success
		
	virtual def EnterRule(rule as PegRule):
		return _ruleState.EnterRule()
		
	virtual def LeaveRule(rule as PegRule, success as bool):
		return _ruleState.LeaveRule(rule, success)
		
	def Try(e as PegExpression):
		return WithState(_state.BeginChoice(), e)
		
	def Test(e as PegExpression):
		return WithState(PredicateState(self), e)

	def WithState(state as PegState, e as PegExpression):
		old = _state
		_state = state
		try:
			if Match(e):
				_state.Commit()
				return true
			else:
				_state.Rollback()
				return false		
		ensure:
			_state = old
						
	def GetMemento():
		return (_ruleState, _input.Mark())
		
	def WithMemento(memento as (object), action as PegAction):
		saved = GetMemento()
		Restore(memento)
		try:
			action(self)
		ensure:
			Restore(saved)
			
	def Restore(memento as (object)):
		ruleState, inputMarker = memento
		_ruleState = ruleState
		_input.Reset(inputMarker)
		
	def OnAction(action as PegAction):
		_state.OnAction(action)
		
class PegDebugContext(PegContext):
	def constructor(text as string):
		super(text)
		
	override def EnterRule(rule as PegRule):
		print ">", rule, _input.Position
		return super(rule)
		
	override def LeaveRule(rule as PegRule, success as bool):
		print "<", rule, success, _input.Position
		return super(rule, success)
		
class PegRuleState:
	
	_ctx as PegContext
	
	def constructor(ctx as PegContext):
		_ctx = ctx
		
	virtual MatchBegin:
		get: return -1
		
	virtual def LastMatchFor(rule as PegRule):
		return string.Empty
	
	def EnterRule():
		return PegRuleStateNested(_ctx, self)
		
	virtual def LeaveRule(rule as PegRule, success as bool) as PegRuleState:
		assert false		
		
class PegRuleStateNested(PegRuleState):

	_parent as PegRuleState
	_matchBegin as int
		
	def constructor(ctx as PegContext, parent as PegRuleState):
		super(ctx)
		_parent = parent
		_matchBegin = ctx.Input.Mark()
		
	override MatchBegin:
		get: return _matchBegin
		
	override def LeaveRule(rule as PegRule, success as bool):
		if success: return PegRuleStateMatched(_ctx, _parent, rule, _matchBegin)
		return _parent
		
	override def LastMatchFor(rule as PegRule):
		return _parent.LastMatchFor(rule)
		
class PegRuleStateMatched(PegRuleStateNested):

	_rule as PegRule
	_ruleMatchBegin as int

	def constructor(ctx as PegContext, parent as PegRuleState, rule as PegRule, ruleMatchBegin as int):
		super(ctx, parent)
		_rule = rule
		_ruleMatchBegin = ruleMatchBegin
		
	Text:
		get: return _ctx.Input.Text[_ruleMatchBegin:_matchBegin]
		
	override def LeaveRule(rule as PegRule, success as bool) as PegRuleState:
		return _parent.LeaveRule(rule, success)
				
	override MatchBegin:
		get: return _parent.MatchBegin
		
	override def LastMatchFor(rule as PegRule):
		if rule is _rule: return Text
		return super(rule)
		
def text(ctx as PegContext):
	return ctx.Input.TextFrom(ctx.RuleState.MatchBegin)