"""
John Cleese
"""
import java.lang

class Person:
	public name as string
	
	def constructor(name as string):
		self.name = name
	
funnyGuy = Person("John Cleese")
System.out.println(funnyGuy.name)