"""
ensure
caught: foo
"""
import java.lang

def foo():
	try:
		raise RuntimeException("foo")
	ensure:
		print "ensure"
		
try:
	foo()
except x:
	print "caught:", x.getMessage()