"""
before
true
true
after
"""
import java.lang

print "before"

a = 2
while a:
	print "true"
	a -= 1
	
a = 0
while a:
	print "0 is true"
	
print "after"