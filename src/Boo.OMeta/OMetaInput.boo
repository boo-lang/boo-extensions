namespace Boo.OMeta

import System
import System.Collections

class OMetaInput:

	static def For(enumerable as IEnumerable) as OMetaInput:
		return ForEnumerator(enumerable.GetEnumerator())
		
	static def ForEnumerator(enumerator as IEnumerator) as OMetaInput:
		return ForEnumerator(enumerator, 0)
		
	static def ForEnumerator(enumerator as IEnumerator, position as int) as OMetaInput:
		if enumerator.MoveNext():
			return EnumeratorInput(enumerator, position)
		return Empty()
		
	static def Prepend(argument, input as OMetaInput):
		return OMetaInputCons(argument, input)
		
	static def Singleton(o):
		return Prepend(o, Empty())
		
	static def Empty():
		return OMetaInput()
	
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
		
	virtual def SetMemo(key as string, value) as OMetaInput:
		return OMetaInputWithMemo(key, value, self)
		
	virtual def GetMemo(key as string):
		return null
		
	override def ToString():
		return "OMetaInput()"
		
internal class DelegatingInput(OMetaInput):
	
	final _input as OMetaInput
	
	def constructor(input as OMetaInput):
		_input = input
	
	override Head:
		get: return _input.Head
	
	override IsEmpty:
		get: return _input.IsEmpty
		
	override Tail:
		get: return _input.Tail
						
	override Position:
		get: return _input.Position
		
	override def SetMemo(key as string, value):
		return _input.SetMemo(key, value)
		
	override def GetMemo(key as string):
		return _input.GetMemo(key)
		
	override def ToString():
		return _input.ToString()
		
internal class OMetaInputWithMemo(DelegatingInput):
	
	final _key as string
	final _value as object
	_tail as OMetaInput
	
	def constructor(key as string, value, input as OMetaInput):
		super(input)
		_key = key
		_value = value
	
	override Tail:
		get:
			if _tail is null:
				_tail = OMetaInputMemoTail(self, _input.Tail)
			return _tail
			
	override def GetMemo(key as string):
		if key is _key: return _value
		return super(key)
		
internal class OMetaInputMemoTail(DelegatingInput):
	
	final _parent as OMetaInput
	_tail as OMetaInput
	
	def constructor(parent as OMetaInput, input as OMetaInput):
		super(input)
		_parent = parent
		
	override Tail:
		get:
			if _tail is null:
				_tail = OMetaInputMemoTail(self, _input.Tail)
			return _tail
		
	override def GetMemo(key as string):
		return _parent.GetMemo(key)
		
internal class OMetaInputCons(OMetaInput):
	[getter(Head)] _argument as object
	[getter(Tail)] _tail as OMetaInput
	
	def constructor(argument, tail as OMetaInput):
		_argument = argument
		_tail = tail
		
	override IsEmpty:
		get: return false

internal class EnumeratorInput(OMetaInput):
	
	final _position as int
	final _input as IEnumerator
	final _head as object
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
