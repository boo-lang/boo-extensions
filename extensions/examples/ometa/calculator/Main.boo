import Boo.OMeta
import Boo.Adt

data Exp = Const(value as int) | Infix(operator as string, left as Exp, right as Exp)

ometa Calculator:
	num = ++digit >> value ^ Const(int.Parse(value.ToString()))
	exp = sum | fac
	sum = (fac >> x, '+', fac >> y) ^ Infix("+", x, y)
	fac = mult | atom
	mult = (atom >> x,'*', atom >> y) ^ Infix("*", x, y)
	atom = num | parens
	parens = ('(', exp >> value, ')') ^ value
	
ometa XE < Calculator:
	fac = division | super
	division = (atom >> x, '/', atom >> y) ^ Infix("/", x, y)

c = XE()
while true:
	line = prompt("> ")
	if string.IsNullOrEmpty(line) or line == "/q": break
	print c.Apply('exp', StringInput(line))
