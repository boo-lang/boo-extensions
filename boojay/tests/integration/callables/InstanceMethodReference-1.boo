"""
42
ltuae
"""
namespace callables

class Item:
	public value = null
	def getValue():
		return value
		
item = Item(value: "42")
getValue = item.getValue
print getValue()
item.value = "ltuae"
print getValue()