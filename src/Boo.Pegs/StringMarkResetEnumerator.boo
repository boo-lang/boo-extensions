namespace Boo.Pegs

# TODO: generalize the MarkResetEnumerator interface
# to be able to parse other structures as well
# (it should be possible to build a peg to recognize IL bytecode
# sequences, for instance)
class StringMarkResetEnumerator:
	
	_next = 0

	[getter(Text)]
	_text as string
	
	def constructor(text as string):
		_text = text
		
	def TextFrom(startIndex as int):
		if _next: return _text[startIndex:_next]
		return string.Empty
		
	Position:
		get:
			return _next
		
	CurrentChar:
		get:
			return _text[_next-1]
			
	def MoveNext():
		if _next < len(_text):
			++_next
			return true
		return false
		
	def MovePrevious():
		assert _next > 0
		--_next

	def Mark():
		return _next
		
	def Reset(mark as int):
		_next = mark
