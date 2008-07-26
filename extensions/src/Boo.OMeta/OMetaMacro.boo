namespace Boo.OMeta

import Boo.PatternMatching
import Boo.Lang.Compiler.Ast

macro ometa:
	
	def enclosingTypeDefinition():
		type as TypeDefinition = ometa.GetAncestor(NodeType.ClassDefinition) or ometa.GetAncestor(NodeType.Module)
		return type
	
	type = OMetaMacroProcessor(ometa).expandType()
	enclosingTypeDefinition().Members.Add(type)
	
macro option:
	
	assert 1 == len(option.Arguments)
	assert 0 == len(option.Block.Statements)
	
	match option.Arguments[0]:
		case ReferenceExpression(Name: value):
			parent = option.GetAncestor(NodeType.MacroStatement)
			options as List = parent["options"]
			if options is null:
				parent["options"] = [value]
			else:
				options.Add(value)