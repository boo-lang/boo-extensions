"""
before
evaluated
after
before
evaluated
evaluated
after
"""

def fun(value):
	print 'evaluated'
	return value
	
a = null and true
assert a is null

b = true and 3
assert b == 3

print "before"
c = fun(false) and fun(true)
print "after"
assert c == false

print "before"
d = fun(true) and fun(null)
print "after"
assert d is null

e = 0 and false
assert e == 0
