namespace Boo.OMeta

class StringInput(OMetaInput):
	
	final _input as string
	final _position as int
	_tail as OMetaInput
	
	def constructor(input as string):
		_input = input
	
	def constructor(input as string, position as int):
		_input = input
		_position = position
		
	IsEmpty:
		get: return _position >= _input.Length
		
	Head:
		get: return _input[_position]
	
	Tail:
		get:
			if _tail is null:
				_tail = StringInput(_input, _position+1)
			return _tail
		
	override def ToString():
		return "StringInput(${(null if IsEmpty else 'Head: ' + Head)})"

def any(input as OMetaInput) as OMetaMatch:
	if input.IsEmpty: return FailedMatch(input)
	return SuccessfulMatch(input.Tail, input.Head)
	
def character(input as OMetaInput, expected as char) as OMetaMatch:
	if not input.IsEmpty and expected.Equals(input.Head):
		return SuccessfulMatch(input.Tail, input.Head)
	return FailedMatch(input)
	
def string_(input as OMetaInput, expected as string) as OMetaMatch:
	for ch in expected:
		m = character(input, ch)
		if m isa FailedMatch: return m
		input = m.Input
	return SuccessfulMatch(input, expected)
