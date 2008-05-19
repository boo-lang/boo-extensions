"""
before
1 is true
0 is false
after
"""
import java.lang

print "before"

a = 1
if a:
	print "1 is true"
	
a = 0
if a:
	print "0 is true"
else:
	print "0 is false"
	
print "after"