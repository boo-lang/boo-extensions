namespace pegs

import Boo.Pegs

def push(ctx as PegContextWithPayload[of List], value as int):
	ctx.Payload.Push(value)

def pop(ctx as PegContextWithPayload[of List]) as int:
	return ctx.Payload.Pop()
	
peg:
	evaluate = spacing, addition, eof
	addition = term, --("+", spacing, term, { $push($pop + $pop) })
	term = factor, --("*", spacing, factor, { $push($pop * $pop) })
	factor = ++digit(), { $push(int.Parse($text)) }, spacing
	spacing = --whitespace()
	eof = not any()

while true:
	expression = prompt("> ")
	if string.IsNullOrEmpty(expression): break
	ctx = PegContextWithPayload[of List](expression, [])
	if evaluate.Eval(ctx):
		print pop(ctx)
	else:
		print "DOES NOT COMPUTE!"