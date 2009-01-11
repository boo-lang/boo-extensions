"""
FOO
BAR
"""
namespace generators

def foobar():
	yield "foo"
	yield "bar"
	
for s in foobar():
	print s.toUpperCase()