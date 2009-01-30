"""
Not implemented
"""
namespace types

interface INotImplemented:
	def foo()
	
class NotImplemented(INotImplemented):
	pass
	
def use(o as INotImplemented):
	o.foo()
	
try:
	use NotImplemented()
	print "shouldn't get here"
except as NotImplementedException:
	print "Not implemented"