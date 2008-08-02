namespace Boo.OMeta

import Boo.PatternMatching

def any(input as OMetaInput) as OMetaMatch:
	if input.IsEmpty: return FailedMatch(input, EndOfInput)
	return SuccessfulMatch(input.Tail, input.Head)

def any_rule(context as OMetaGrammar, input as OMetaInput):
	return any(input)
	
def character(input as OMetaInput, expected as char) as OMetaMatch:
	if input.IsEmpty:
		return FailedMatch(input, RuleFailure('character', EndOfInput))
	if not expected.Equals(input.Head):
		return FailedMatch(input, RuleFailure('character', ExpectedValueFailure(expected)))
	return SuccessfulMatch(input.Tail, expected.ToString())
	
def characters(input as OMetaInput, expected as string) as OMetaMatch:
	for ch in expected:
		m = character(input, ch)
		if m isa FailedMatch: return FailedMatch(input, ExpectedValueFailure(expected))
		input = m.Input
	return SuccessfulMatch(input, expected)
	
def scan(grammar as OMetaGrammar, rule as string, input as System.Collections.IEnumerable):
	return scan(grammar, rule, OMetaInput.For(input))
	
def scan(grammar as OMetaGrammar, rule as string, input as OMetaInput):
	while not input.IsEmpty:
		match grammar.Apply(grammar, rule, input):
			case SuccessfulMatch(Input, Value):
				input = Input
				yield Value
				
def flatten(items) as object*:
	if items is null: return
	e1 = items as System.Collections.IEnumerable
	if e1 is null:
		yield items
		return
	for item in e1:
		yieldAll flatten(item)