namespace Boo.OMeta

interface OMetaInput:
	
	IsEmpty as bool:
		get
	
	Head as object:
		get
		
	Tail as OMetaInput:
		get