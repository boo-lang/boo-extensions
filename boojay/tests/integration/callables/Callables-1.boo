"""
FOO
"""
class ToUpper(callable):
	def Call(args as (object)) as object:
		return (args[0] as string).toUpperCase()

a = ToUpper()
print a("foo")
