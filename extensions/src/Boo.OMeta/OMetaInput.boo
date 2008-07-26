namespace Boo.OMeta

import System
import System.Collections

class OMetaInput:

	public static final Empty as OMetaInput = OMetaInput()
	
	static def For(enumerable as IEnumerable) as OMetaInput:
		return ForEnumerator(enumerable.GetEnumerator())
		
	static def ForEnumerator(enumerator as IEnumerator) as OMetaInput:
		return ForEnumerator(enumerator, 0)
		
	static def ForEnumerator(enumerator as IEnumerator, position as int) as OMetaInput:
		if enumerator.MoveNext():
			return EnumeratorInput(enumerator, position)
		return Empty
		
	static def Prepend(argument, input as OMetaInput):
		return OMetaInputCons(argument, input)
		
	static def Singleton(o):
		return Prepend(o, Empty)
	
	protected def constructor():
		pass
		
	virtual IsEmpty as bool:
		get: return true
		
	virtual Head as object:
		get: raise InvalidOperationException()
		
	virtual Tail as OMetaInput:
		get: raise InvalidOperationException()
		
	virtual Position:
		get: return int.MaxValue
		
	override def ToString():
		return "OMetaInput()"
		
internal class OMetaInputCons(OMetaInput):
	[getter(Head)] _argument
	[getter(Tail)] _tail as OMetaInput
	
	def constructor(argument, tail as OMetaInput):
		_argument = argument
		_tail = tail
		
	override IsEmpty:
		get: return false

internal class EnumeratorInput(OMetaInput):
	
	final _position as int
	final _input as IEnumerator
	final _head
	_tail as OMetaInput
	
	internal def constructor(input as IEnumerator, position as int):
		_input = input
		_head = input.Current
		_position = position
		
	override Position:
		get: return _position
		
	override IsEmpty:
		get: return false
		
	override Head:
		get: return _head
	
	override Tail:
		get:
			if _tail is null:
				_tail = ForEnumerator(_input, _position + 1)
			return _tail
		
	override def ToString():
		return "OMetaInput(Head: ${Head}, Position: ${Position})"
