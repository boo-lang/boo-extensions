namespace Boo.OMeta

class OMetaList(OMetaInput):
	
	public static final Empty = OMetaList()
	
	protected def constructor():
		pass
	
	IsEmpty:
		get: return true
		
	Head:
		get: raise System.InvalidOperationException()
		
	Tail:
		get: raise System.InvalidOperationException()
		
	virtual def Each(action as System.Action[of object]):
		pass
		
	virtual def Reverse():
		return self
		
	override def ToString():
		return string.Empty
		
	override def Equals(o):
		return o is self
		
class OMetaCons(OMetaList):
	
	final _head
	final _tail as OMetaList
	
	def constructor(head):
		self(head, OMetaList.Empty)
	
	def constructor(head, [required] tail as OMetaList):
		_head = head
		_tail = tail
		
	override IsEmpty:
		get: return false
		
	override Head:
		get: return _head
		
	override Tail:
		get: return _tail
		
	override def Equals(o):
		other = o as OMetaList
		if other is null or other.IsEmpty: return false
		if _head != other.Head: return false
		return _tail.Equals(other.Tail)
			
	override def Each(action as System.Action[of object]):
		action(_head)
		_tail.Each(action)
		
	override def Reverse():
		if _tail.IsEmpty: return self
		
		result = OMetaList.Empty
		Each { o | result = OMetaCons(o, result) }
		return result
		
	override def ToString():
		buffer = System.Text.StringBuilder()
		Each { o | buffer.Append(o) }
		return buffer.ToString()
		
def list(*elements):
	result = OMetaList.Empty
	for i in range(1, len(elements)+1):
		result = OMetaCons(elements[-i], result)
	return result