import Boo.OMeta
import Boo.Adt
import Boo.PatternMatching
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

data Exp = Const(value as int) | Infix(operator as string, left as Exp, right as Exp)

// using macros to generate more complex ometa rules
// is indeed a good idea
macro infix:
	
	l, op, r = infix.Arguments
	
	return ExpressionStatement([| $l = ((($l >> l, $op >> op, $r >> r) ^ Infix(op, l, r)) | $r) |])

ometa Parser:
	parse = sum
	infix sum, ('+' | '-'), fac
	infix fac, ('*' |  '/'), atom
	atom = num | parens
	parens = ('(', exp >> value, ')') ^ value
	num = ++digit >> value ^ Const(int.Parse(join(value, '')))
	
// See, Mom! No visitors!
ometa Evaluator:
	eval = const | infix
	const = Const(value) ^ value
	infix = sum | subtraction | mult | division

	// we could certainly use a macro here too
	sum = Infix(operator: "+", left: eval >> l, right: eval >> r) ^ add(l, r)
	subtraction = Infix(operator: "-", left: eval >> l, right: eval >> r) ^ subtract(l, r)
	mult = Infix(operator: "*", left: eval >> l, right: eval >> r) ^ multiply(l, r)
	division = Infix(operator: "/", left: eval >> l, right: eval >> r) ^ divide(l, r)
	
	def add(x as int, y as int):
		return x + y
		
	def subtract(x as int, y as int):
		return x - y

	def multiply(x as int, y as int):
		return x * y

	def divide(left as int, right as int):
		return left / right

while true:
	line = prompt("> ")
	if string.IsNullOrEmpty(line) or line == "/q": break
	match m=Parser().parse(OMetaInput.For(line.Trim())):
		case SuccessfulMatch(Value, Input: OMetaInput(IsEmpty: true)):
			print Evaluator().eval(OMetaInput.Singleton(Value))
		otherwise:
			print m
