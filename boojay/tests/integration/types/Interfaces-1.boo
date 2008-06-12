"""
yeah
"""
interface Foo:
	def bar()

class FooImpl(Foo):
	def bar():
		java.lang.System.out.println("yeah")
		
def useFoo(f as Foo):
	f.bar()
	
useFoo(FooImpl())    
