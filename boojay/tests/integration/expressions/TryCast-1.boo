"""
FOO
foo
null
"""
def sysout(o):
	if o is null:
		print "null"
	if o is not null:
		print o

o as object = "foo"
s as string = o
sysout s.toUpperCase()
sysout o as string
sysout o as java.lang.Integer
