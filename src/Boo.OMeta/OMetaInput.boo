namespace Boo.OMeta

import System
import System.Collections
import System.Collections.Specialized

class OMetaInput:

	static def For(enumerable as IEnumerable) as OMetaInput:
		return ForEnumerator(enumerable.GetEnumerator())
		
	static def ForEnumerator(enumerator as IEnumerator) as OMetaInput:
		return ForEnumerator(enumerator, 0, null)
		
	static def ForEnumerator(enumerator as IEnumerator, position as int, prev as OMetaInput) as OMetaInput:
		if enumerator.MoveNext():
			return EnumeratorInput(enumerator, position, prev)
		return EndOfEnumeratorInput(position, prev)
		
	static def Prepend(argument, input as OMetaInput, prev as OMetaInput):
		return OMetaInputCons(argument, input, prev)
		
	static def Singleton(o):
		return Prepend(o, Empty(), null)
		
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

	virtual Prev as OMetaInput:
		get: return null

	virtual def SetMemo(key as string, value) as OMetaInput:
		return OMetaInputWithMemo(key, value, self, Prev)
		
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
		
	override Prev:
		get: return _input.Prev		
		
	override def SetMemo(key as string, value):
		return _input.SetMemo(key, value)
		
	override def GetMemo(key as string):
		return _input.GetMemo(key)
		
	override def ToString():
		return _input.ToString()
		
internal class OMetaInputWithMemo(DelegatingInput):
	final _dictionary as ListDictionary
	_tail as OMetaInput
	final _prev as OMetaInput	
	
	def constructor(key as string, value, input as OMetaInput, prev):
		super(input)
		_dictionary = ListDictionary()
		_dictionary.Add(key, value)
		_prev = prev
	
	protected def constructor(input as OMetaInput, prev, dictionary as ListDictionary):
		super(input)
		_dictionary = dictionary
		_prev = prev
	
	protected def Clone():
		dictionaryCopy = ListDictionary()
		for item as DictionaryEntry in _dictionary:	dictionaryCopy.Add(item.Key, item.Value)
		return OMetaInputWithMemo(_input, _prev, dictionaryCopy)
	
	protected def SetDictionaryEntry(key as string, value):
		_dictionary[key] = value
 	
	override Tail:
		get: return _tail or _tail = OMetaInputMemoTail(self, _input.Tail, self)
		
	override Prev:
		get: return _prev		
			
	override def SetMemo(key as string, value) as OMetaInput:
		newInputWithMemo = Clone()
		newInputWithMemo.SetDictionaryEntry(key, value)
		return newInputWithMemo
		
	override def GetMemo(key as string):
		if _dictionary.Contains(key): return _dictionary[key]
		return _input.GetMemo(key)
		
internal class OMetaInputMemoTail(DelegatingInput):
	
	final _parent as OMetaInputWithMemo
	_tail as OMetaInput
	final _prev as OMetaInput
	
	def constructor(parent as OMetaInputWithMemo, input as OMetaInput, prev as OMetaInput):
		super(input)
		_parent = parent
		_prev = prev
		
	override Prev:
		get: return _prev

	override Tail:
		get: return _tail or _tail = OMetaInputMemoTail(_parent, _input.Tail, self)
		
	override def SetMemo(key as string, value) as OMetaInput:
		return OMetaInputMemoTail(_parent.SetMemo(key, value), _input, _prev)
		
	override def GetMemo(key as string):
		return _parent.GetMemo(key)
		
internal class OMetaInputCons(OMetaInput):
	[getter(Head)] _head as object
	[getter(Tail)] _tail as OMetaInput
	final _prev as OMetaInput
	
	def constructor(head, tail as OMetaInput, prev as OMetaInput):
		_head = head
		_tail = tail
		_prev = prev
		
	override Prev:
		get: return _prev

	override IsEmpty:
		get: return false

internal class EnumeratorInput(OMetaInput):
	
	final _position as int
	final _input as IEnumerator
	final _head as object
	final _prev as OMetaInput
	_tail as OMetaInput
	
	internal def constructor(input as IEnumerator, position as int, prev as OMetaInput):
		_input = input
		_head = input.Current
		_position = position
		_prev = prev
		
	override Position:
		get: return _position
		
	override IsEmpty:
		get: return false
		
	override Head:
		get: return _head
	
	override Tail:
		get: return _tail or _tail = ForEnumerator(_input, _position + 1, self)
	
	override Prev:
		get: return _prev
		
	override def ToString():
		return "OMetaInput(Head: ${Head}, Position: ${Position})"
		

		
internal class EndOfEnumeratorInput(OMetaInput):	
	final _prev as OMetaInput

	def constructor(position as int, prev as OMetaInput):
		_position = position
		_prev = prev

	override Prev:
		get: return _prev

	[getter(Position)]
	_position as int
