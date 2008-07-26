namespace Boo.OMeta.Parser

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro syntax:
	
	module as Module = syntax.GetAncestor(NodeType.Module)

	syntaxExtensionName =  AstUtil.CreateReferenceExpression("${module.Namespace.Name}.${syntax.Arguments[0]}")
	
	syntaxAttribute = Attribute(Name: typeof(SyntaxExtensionAttribute).FullName)
	syntaxAttribute.Arguments.Add([| $syntaxExtensionName |])
	module.AssemblyAttributes.Add(syntaxAttribute)
	
#	module.Imports.Add(Import(LexicalInfo: syntax.LexicalInfo, Namespace: "Boo.Lang.OMeta"))
	
	return MacroStatement(Name: "ometa", Arguments: syntax.Arguments, Block: syntax.Block)