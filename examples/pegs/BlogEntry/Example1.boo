import Boo.Pegs

peg:
	grammar = spaces, addition, eof
	addition = term, --("+", spaces, term)
	term = factor, --("*", spaces, factor)
	factor = ++[0-9], spaces
	spaces = --(' ' / '\t')
	eof = not any()
	
assert grammar.Match(PegContext("  6*6 + 6 "))
