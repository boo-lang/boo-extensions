namespace pegs

import Boo.Pegs
import System.Collections.Generic

// actions in the peg are just closures
// so they can see whatever variables were introduced
// before the peg definition

stack = Stack[of int]()
push = stack.Push
pop = stack.Pop
	
peg:
	calculator = spaces, addition, eof
	addition = term, --("+", spaces, term, { push(pop() + pop()) })
	term = factor, --("*", spaces, factor, { push(pop() * pop()) })
	factor = ++digit(), { push(int.Parse($text)) }, spaces
	spaces = --whitespace()
	eof = not any()

while true:
	expression = prompt("> ")
	if string.IsNullOrEmpty(expression): break
	
	ctx = PegContext(expression)
	if calculator.Match(ctx):
		print pop()
	else:
		print "--" + "-" * ctx.Input.Position + "^"
		print "DOES NOT COMPUTE!"
		
	stack.Clear()
