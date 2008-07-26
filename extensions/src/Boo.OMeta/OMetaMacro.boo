namespace Boo.OMeta

import Boo.Lang.Compiler.Ast

macro ometa:
	
	def enclosingTypeDefinition():
		type as TypeDefinition = ometa.GetAncestor(NodeType.ClassDefinition) or ometa.GetAncestor(NodeType.Module)
		return type
	
	type = OMetaMacroProcessor(ometa).expandType()
	enclosingTypeDefinition().Members.Add(type)