"""
before
during
ensure
before
ensure
"""
namespace generators

def tryEnsureAround(source):
	print "before"
	try:
		for item in source:
			yield item
	ensure:
		print "ensure"
		
def generator(withError as bool):
	assert not withError
	yield "during"
	
for item in tryEnsureAround(generator(false)):
	print item
try:
	for item in tryEnsureAround(generator(true)):
		print item

	print "should never get here"
except:
	pass