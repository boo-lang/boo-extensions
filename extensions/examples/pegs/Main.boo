namespace pegs

import Boo.Pegs

def push(ctx as PegContextWithPayload[of List], value as int):
	ctx.Payload.Push(value)

def pop(ctx as PegContextWithPayload[of List]) as int:
	return ctx.Payload.Pop()
	
peg:
	evaluate = spacing, addition, eof
	addition = term, --("+", term, { $push($pop + $pop) })
	term = factor, --("*", factor, { $push($pop * $pop) })
	factor = ++digit(), { $push(int.Parse($text)) }, spacing
	spacing = --whitespace()
	eof = not any()

ctx = PegContextWithPayload[of List]("3+2*4", [])
print evaluate.Eval(ctx)
print pop(ctx)