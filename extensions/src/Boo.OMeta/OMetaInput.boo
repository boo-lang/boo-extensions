namespace Boo.OMeta

import System
import System.Collections

class OMetaInput:

	public static final Empty as OMetaInput = OMetaInput()
	
	static def For(enumerable as IEnumerable) as OMetaInput:
		return ForEnumerator(enumerable.GetEnumerator())
		
	static def ForEnumerator(enumerator as IEnumerator) as OMetaInput:
		if enumerator.MoveNext():
			return EnumeratorInput(enumerator)
		return Empty
	
	protected def constructor():
		pass
	
	virtual IsEmpty as bool:
		get: return true
		
	virtual Head as object:
		get: raise InvalidOperationException()
		
	virtual Tail as OMetaInput:
		get: raise InvalidOperationException()

internal class EnumeratorInput(OMetaInput):
	
	final _input as IEnumerator
	_tail as OMetaInput
	_head
	
	internal def constructor(input as IEnumerator):
		_input = input
		_head = input.Current
		
	override IsEmpty:
		get: return false
		
	override Head:
		get: return _head
	
	override Tail:
		get:
			if _tail is null:
				_tail = ForEnumerator(_input)
			return _tail
		
	override def ToString():
		return "EnumeratorInput(Head: ${Head})"
