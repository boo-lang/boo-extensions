namespace Boo.OMeta

class MemoKey:
	
	public final rule as string
	public final input as OMetaInput
	
	def constructor(rule as string, input as OMetaInput):
		self.rule = rule
		self.input = input
		
	override def Equals(o):
		other as MemoKey = o
		return input is other.input and rule is other.rule
		
	override def GetHashCode():
		return rule.GetHashCode() ^ input.GetHashCode()
		
	override def ToString():
		return "MemoKey(${rule}, ${input})"