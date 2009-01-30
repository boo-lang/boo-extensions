namespace Boojay.Lang

abstract class Generator(Enumerable):
	pass
	
abstract class GeneratorEnumerator(Enumerator):
	_current = null
	_state = 0
	
	Current:
		get: return _current

	protected def Yield(state as int, value):
		_state = state
		_current = value
		return true
		
	def Dispose():
		_current = null
