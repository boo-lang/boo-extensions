"""
yeah
yeah
Equals
true
Equals
false
"""
class Overrides1:
	def ToString():
		return "yeah"
	def Equals(o):
		print "Equals"
		return super(o)
		
o1 = Overrides1()
o2 = Overrides1()
print o1
print o2.ToString()
print o1.Equals(o1)
print o1.Equals(o2)