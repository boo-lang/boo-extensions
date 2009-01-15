namespace Boojay.Lang

class List(java.util.ArrayList):
	
	def constructor():
		pass
		
	def constructor(initialCapacity as int):
		super(initialCapacity)
	
	def constructor(items as object*):
		for item in items:
			add(item)
			
	self[index as int]:
		get: self.get(index)
		set: self.set(index, value)