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
	calculator = spacing, addition, eof
	addition = term, --("+", spacing, term, { push(pop() + pop()) })
	term = factor, --("*", spacing, factor, { push(pop() * pop()) })
	factor = ++digit(), { push(int.Parse($text)) }, spacing
	spacing = --whitespace()
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
