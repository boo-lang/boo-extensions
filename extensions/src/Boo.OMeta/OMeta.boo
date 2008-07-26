namespace Boo.OMeta

def any(input as OMetaInput) as OMetaMatch:
	if input.IsEmpty: return FailedMatch(input)
	return SuccessfulMatch(input.Tail, input.Head)
	
def character(input as OMetaInput, expected as char) as OMetaMatch:
	if not input.IsEmpty and expected.Equals(input.Head):
		return SuccessfulMatch(input.Tail, input.Head)
	return FailedMatch(input)
	
def characters(input as OMetaInput, expected as string) as OMetaMatch:
	for ch in expected:
		m = character(input, ch)
		if m isa FailedMatch: return m
		input = m.Input
	return SuccessfulMatch(input, expected)
