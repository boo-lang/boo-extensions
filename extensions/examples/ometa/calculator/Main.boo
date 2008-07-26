import Boo.OMeta
import Boo.Adt
import Boo.PatternMatching

data Exp = Const(value as int) | Infix(operator as string, left as Exp, right as Exp)

ometa E:
	num = ++digit >> value ^ Const(int.Parse(join(value, '')))
	exp = sum | fac
	sum = (fac >> x, '+', fac >> y) ^ Infix("+", x, y)
	fac = mult | atom
	mult = (atom >> x,'*', atom >> y) ^ Infix("*", x, y)
	atom = num | parens
	parens = ('(', exp >> value, ')') ^ value
	
ometa XE < E:
	fac = division | super
	division = (atom >> x, '/', atom >> y) ^ Infix("/", x, y)
	
	
// See, Mom! No visitors!
ometa Evaluator:
	eval = const | infix
	const = Const(value) ^ value
	infix = sum | mult
	sum = Infix(operator: "+", left: eval >> l, right: eval >> r) ^ add(l, r)
	mult = Infix(operator: "*", left: eval >> l, right: eval >> r) ^ multiply(l, r)
	def add(x as int, y as int):
		return x + y
	def multiply(x as int, y as int):
		return x * y

ometa XEvaluator < Evaluator:
	eval = division | super
	division = Infix(operator: "/", left: eval >> l, right: eval >> r) ^ divide(l, r)
	def divide(left as int, right as int):
		return left / right

while true:
	line = prompt("> ")
	if string.IsNullOrEmpty(line) or line == "/q": break
	match m=XE().Apply('exp', OMetaInput.For(line)):
		case SuccessfulMatch(Value):
			print XEvaluator().eval(OMetaInput.Singleton(Value))
		otherwise:
			print m
