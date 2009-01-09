"""
before
in between
after
"""
namespace generator

def simplest():
	print "before"
	yield null
	print "after"
	
for item in simplest():
	print "in between"