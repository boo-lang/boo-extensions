import Boo.OMeta
import Boo.Adt

data Exp = Const(value as int) | Infix(operator as string, left as Exp, right as Exp)

ometa E:
	num = ++digit >> value ^ Const(int.Parse(value.ToString()))
	exp = sum | fac
	sum = (fac >> x, '+', fac >> y) ^ Infix("+", x, y)
	fac = mult | atom
	mult = (atom >> x,'*', atom >> y) ^ Infix("*", x, y)
	atom = num | parens
	parens = ('(', exp >> value, ')') ^ value
	
ometa XE < E:
	fac = division | super
	division = (atom >> x, '/', atom >> y) ^ Infix("/", x, y)
	
#ometa Evaluator:
#	eval = const | infix
#	const = Const(value) ^ value
#	infix = sum | mult
#	sum = Infix(operator: "+", eval >> left, eval >> right) ^ (left + right)
#	mult = Infix(operator: "+", eval >> left, eval >> right) ^ (left * right)
#	

c = XE()
while true:
	line = prompt("> ")
	if string.IsNullOrEmpty(line) or line == "/q": break
	print c.Apply('exp', OMetaInput.For(line))
