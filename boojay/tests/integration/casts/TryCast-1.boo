"""
foo
null
"""
def sysout(o):
	if o is null:
		print "null"
	else:
		print o

o as object = "foo"
sysout o as string
sysout o as java.lang.Integer
