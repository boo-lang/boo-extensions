"""
FOO
"""
import java.lang

o as object = "foo"
s = cast(string, o)
print s.toUpperCase()
try:
	print cast(Integer, o)
except x as ClassCastException:
	print "exception"
