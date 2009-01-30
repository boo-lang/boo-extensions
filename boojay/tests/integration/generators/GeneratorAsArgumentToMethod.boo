"""
A STRING
"""
namespace generators

def producer() as string*:
	yield "a string"

def consume(strings as string*):
	for s in strings:
		print s.toUpperCase()
		
consume producer()