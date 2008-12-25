import Boo.OMeta
import Boo.Adt
import Boo.Lang.PatternMatching
import Boo.Lang

data Exp = Const(value as int) | Infix(operator as string, left as Exp, right as Exp)

ometa Parser:
	parse = sum
	sum = (sum >> l, ('+' | '-') >> op, fac >> r) ^ Infix(op, l, r) | fac 
	fac = (fac >> l, ('*' |  '/') >> op, atom >> r) ^ Infix(op, l, r) | atom
	atom = num | parens
	parens = ('(', sum >> value, ')') ^ value
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
	m=Parser().parse(OMetaInput.For(line.Trim()))
	match m:
		case SuccessfulMatch(Value, Input: OMetaInput(IsEmpty: true)):
			print Evaluator().eval(OMetaInput.Singleton(Value))
		otherwise:
			print m
