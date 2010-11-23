import Boo.Adt
import Boo.Lang.PatternMatching

data Expression = Const(value as int) \
	| Sum(left as Expression, right as Expression)

def eval(e as Expression) as int:
   match e:
      case Const(value):
      	return value
      case Sum(left, right):
      	return eval(left) + eval(right)
      
def simplify(e as Expression) as Expression:
	match e:
		case Sum(left: Const(value: 0), right):
			return simplify(right)
		case Sum(left, right: Const(value: 0)):
			return simplify(left)
		case Sum(left, right):
			return Sum(simplify(left), simplify(right))
		otherwise:
			return e

e = Sum(Sum(Const(19), Const(0)), Sum(Const(0), Const(23)))

print simplify(e)
print eval(e) 
print eval(simplify(e))