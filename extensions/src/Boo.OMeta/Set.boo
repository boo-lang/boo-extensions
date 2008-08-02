namespace Boo.OMeta

class Set[of T](T*):
	
	_elements = Boo.Lang.List[of T]()
	
	def constructor():
		pass
		
	def constructor(elements as T*):
		for element in elements: Add(element)
	
	def Add(element as T):
		_elements.AddUnique(element)
		
	def Contains(element as T) as bool:
		return _elements.Contains(element)
		
	def Remove(element as T):
		_elements.Remove(element)
		
	def System.Collections.IEnumerable.GetEnumerator():
		return (self as T*).GetEnumerator()
		
	def GetEnumerator():
		return _elements.GetEnumerator()
		
	override def ToString():
		return _elements.ToString()