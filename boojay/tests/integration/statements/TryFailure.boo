"""
nothing wrong here
still ok
something bad happened
wahoo!
"""
try:
	print "nothing wrong here"
failure:
	print "oops"
	
try:
	try:
		print "still ok"
		raise "wahoo!"
		print "oops"
	failure:
		print "something bad happened"
		
	print "oops"
except x:
	print x.getMessage()