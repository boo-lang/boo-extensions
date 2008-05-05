namespace pegs

import Boo.Pegs

def push(ctx as PegContextWithPayload[of List], value as int):
	ctx.Payload.Push(value)

def pop(ctx as PegContextWithPayload[of List]) as int:
	return ctx.Payload.Pop()
	
// the $ operator inside actions means
// "access the function specified passing the context as the first argument"
// in other words, $pop means pop(context)

peg:
	calculator = spacing, addition, eof
	addition = term, --("+", spacing, term, { $push($pop + $pop) })
	term = factor, --("*", spacing, factor, { $push($pop * $pop) })
	factor = ++digit(), { $push(int.Parse($text)) }, spacing
	spacing = --whitespace()
	eof = not any()

while true:
	expression = prompt("> ")
	if string.IsNullOrEmpty(expression): break
	ctx = PegContextWithPayload[of List](expression, [])
	if calculator.Match(ctx):
		print pop(ctx)
	else:
		print "--" + "-" * ctx.Input.Position + "^"
		print "DOES NOT COMPUTE!"