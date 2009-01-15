namespace Boojay.Lang

class Hash(java.util.HashMap):
	
	def constructor():
		pass
		
	def constructor(initialCapacity as int):
		super(initialCapacity)

	self[key]:
		get: return self.get(key)
		set: self.put(key, value)