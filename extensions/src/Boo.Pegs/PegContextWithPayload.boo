namespace Boo.Pegs

class PegContextWithPayload[of T](PegContext):
		
	[property(Payload)] _payload as T
	
	def constructor(text as string, payload as T):
		super(text)
		_payload = payload
	
	