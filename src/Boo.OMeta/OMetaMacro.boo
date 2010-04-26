namespace Boo.OMeta

import Boo.Lang.PatternMatching
import Boo.Lang.Compiler.Ast

macro ometa:
"""
Compiles ometa matching definition into OMetaGrammar types.

The following patterns are supported:

By default the grammar won't generate parse trees and it will dispatch all rule invocation
dynamically to allow dynamic composition.

A few options can be used to customize the generated code:

	option ParseTree
		causes the grammar to collect parse trees for sequences and repetitions in lists
		
 
"""
	
	enclosingType as TypeDefinition = ometa.GetAncestor(NodeType.ClassDefinition) or ometa.GetAncestor(NodeType.Module)
	type = OMetaMacroProcessor(ometa).expandType()
	enclosingType.Members.Add(type)
	
macro option:
	
	assert 1 == len(option.Arguments)
	assert 0 == len(option.Body.Statements)
	
	match option.Arguments[0]:
		case ReferenceExpression(Name: value):
			parent = option.GetAncestor(NodeType.MacroStatement)
			options as List = parent["options"]
			if options is null:
				parent["options"] = [value]
			else:
				options.Add(value)