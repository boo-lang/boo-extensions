"""
true
false
true
"""
class Exp:
	pass

class Infix(Exp):
	public operator as string
	public left as Exp
	public right as Exp
	
	override def Equals(o):
		if o is null:
			return false
		if self.GetType() is not o.GetType():
			return false
		other as Infix = o
		if self.operator != other.operator:
			return false
		if self.left != other.left:
			return false
		if self.right != other.right:
			return false
		return true
		
e1 = Infix(operator: "+", left: Exp(), right: Exp())
e2 = Infix(operator: "-", left: e1.left, right: e1.right)
print e1 == e1
print e1 == e2
e1.operator = e2.operator
print e1 == e2

