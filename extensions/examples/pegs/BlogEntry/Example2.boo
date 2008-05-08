import Boo.Pegs
import System.Collections.Generic
import System.Globalization

stack = Stack[of int]()
push = stack.Push
pop = stack.Pop

peg:
	grammar = spaces, addition, eof
	addition = term, --("+", spaces, term, { push(pop() + pop()) })
	term = factor, --("*", spaces, factor, { push(pop() * pop()) })
	factor = ++[0-9], { push(int.Parse($text)) }, spaces
	spaces = --(' ' / '\t')
	eof = not any()
	
assert grammar.Match(PegContext("  6*6 + 6 "))
assert 42 == pop()

peg:
	// rebind
	factor.Expression = hex_number / factor.Expression
	hex_number = "0x", ++hex_digit, { push(int.Parse($text[2:], NumberStyles.HexNumber)) }, spaces
	hex_digit = [0-9, a-e, A-E]

assert grammar.Match(PegContext("  0xa*2 + 11*0x02"))
assert 42 == pop()
