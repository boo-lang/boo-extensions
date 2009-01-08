namespace Boojay.Runtime

import java.lang
import java.util

static class RuntimeServices:
	
	def ToBool(o):
		if o is null:
			return false
		boolean = o as Boolean
		if boolean is not null:
			return boolean.booleanValue()
		return true
	
	def UnboxChar(o):
		return cast(Character, o).charValue()
		
	def BoxChar(ch as char):
		return Character(ch)
		
	def UnboxInt32(o):
		return cast(Number, o).intValue()
	
	def EqualityOperator(x, y):
		if x is y: return true
		if x is null: return false
		return x.Equals(y)
		
	def GetEnumerable(source) as Enumerable:
		if source isa Iterable:
			return IterableEnumerable(source)
		if source isa string:
			return StringEnumerable(source)
		raise IllegalArgumentException("source")
		
internal class StringEnumerable(Enumerable):
	_string as string
	def constructor(value as string):
		_string = value
	def GetEnumerator():
		return StringEnumerator(_string)
		
internal class StringEnumerator(Enumerator):
	
	_string as string
	_current = -1
	
	def constructor(value as string):
		_string = value
		
	def MoveNext():
		next = _current + 1
		if next >= len(_string):
			return false
		_current = next
		return true 
		
	Current:
		get: return _string[_current]
		
internal class IterableEnumerable(Enumerable):
	_iterable as Iterable
	def constructor(iterable as Iterable):
		_iterable = iterable
	def GetEnumerator() as Enumerator:
		return IteratorEnumerator(_iterable.iterator())
	
internal class IteratorEnumerator(Enumerator):
	
	_iterator as Iterator
	_current
	
	def constructor(iterator as Iterator):
		_iterator = iterator
		
	def MoveNext():
		if not _iterator.hasNext(): return false
		_current = _iterator.next()
		return true
		
	Current:
		get: return _current