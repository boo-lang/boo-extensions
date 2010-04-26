namespace pegs

import Boo.Pegs

class CalculatorContext(PegContext):
	
	[getter(Stack)] _stack = []
	
	def constructor(text as string):
		super(text)

def push(ctx as CalculatorContext, value as int):
	ctx.Stack.Push(value)

def pop(ctx as CalculatorContext) as int:
	return ctx.Stack.Pop()
	
def readEvalLoop(calculator as PegExpression):
	while true:
		expression = prompt("> ")
		if string.IsNullOrEmpty(expression): break
		ctx = CalculatorContext(expression)
		if calculator.Match(ctx):
			print pop(ctx)
		else:
			print "--" + "-" * ctx.Input.Position + "^"
			print "DOES NOT COMPUTE!"
		
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
	
readEvalLoop calculator
