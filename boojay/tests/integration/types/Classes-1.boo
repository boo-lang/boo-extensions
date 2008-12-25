"""
John Cleese
Albatross
class Person
"""
import java.lang

class Person:
	public name as string
	public father as Person
	
funnyGuy = Person(name: "John Cleese", father: Person(name: "Albatross"))
print funnyGuy.name
print funnyGuy.father.name
print funnyGuy.GetType()