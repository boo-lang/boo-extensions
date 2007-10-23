import Boo.PatternMatching
import Boo.Adt

def eval(e as Expression) as int:
   match e:
      case Const(value):
      	return value
      case Add(left, right):
      	return eval(left) + eval(right)
      
def simplify(e as Expression) as Expression:
	match e:
		case Add(left: Const(value: 0), right):
			return simplify(right)
		case Add(left, right: Const(value: 0)):
			return simplify(left)
		case Add(left, right):
			return Add(simplify(left), simplify(right))
		otherwise:
			return e
      
data Expression = Const(value as int) | Add(left as Expression, right as Expression)

e = Add(Add(Const(19), Const(0)), Add(Const(0), Const(23)))

print simplify(e)
print eval(e) 
print eval(simplify(e))