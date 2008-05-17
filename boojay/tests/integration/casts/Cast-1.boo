"""
foo
null
"""
import java.lang

def sysout(o):
	if o is null:
		System.out.println("null")
	else:
		System.out.println(o)

o as object = "foo"
sysout o as string
sysout o as Integer
