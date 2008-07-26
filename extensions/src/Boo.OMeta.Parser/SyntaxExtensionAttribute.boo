namespace Boo.OMeta.Parser

import System

class SyntaxExtensionAttribute(Attribute):
	
	[getter(Type)] _type as Type
	
	def constructor(type as Type):
		_type = type