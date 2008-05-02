namespace Boo.Pegs

import System.Collections

class StringMarkResetEnumerator(IEnumerator):
	
	_next = 0

	[getter(Text)]
	_text as string
	
	def constructor(text as string):
		_text = text
		
	Position:
		get:
			return _next-1
		
	System.Collections.IEnumerator.Current:
		get:
			return _text[Position]
			
	CurrentChar:
		get:
			return _text[Position]
			
	def MoveNext():
		if _next < len(_text):
			++_next
			return true
		return false
		
	def Dispose():
		pass
		
	def Reset():
		Reset(0)
		
	def Mark():
		return _next
		
	def Reset(mark as int):
		_next = mark
