"""
before
not 1 is false
not 0 is true
after
"""
import java.lang

print "before"

a = 1
if not a:
	print "not 1 is true"
else:
	print "not 1 is false"
	
a = 0
if not a:
	print "not 0 is true"
else:
	print "0 is false"
	
print "after"