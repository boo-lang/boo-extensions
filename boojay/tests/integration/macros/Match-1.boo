"""
Eric Idle
42
"""
import Boo.Lang.PatternMatching

class Person:
	public name as string
	
def personNameOrString(o):
	match o:
		case Person(name):
			return name
		otherwise:
			return o.ToString()

p = Person(name: "Eric Idle")
print personNameOrString(p)
print 42
