"""
A STRING
"""
namespace generators

def producer() as string*:
	yield "a string"

def consume(strings as string*):
	enumerator = strings.getEnumerator()
	while enumerator.moveNext():
		print enumerator.current.toUpperCase()
		
consume producer()