namespace Boo.PatternMatching

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

class CaseMacro(AbstractAstMacro):
	override def Expand(node as MacroStatement):
		
		match = parentMatch(node)
		caseList(match).Add(node)
		
		return null
		
class OtherwiseMacro(AbstractAstMacro):
	override def Expand(node as MacroStatement):
		
		match = parentMatch(node)
		assert match["otherwise"] is null
		match["otherwise"] = node
			
		return null

		
def caseList(node as MacroStatement) as List:
	list as List = node["caseList"]
	if list is null:
		node["caseList"] = list = []
	return list
	
def parentMatch(node as MacroStatement):
	match = node.ParentNode.ParentNode as MacroStatement
	assert match.Name == "match"
	return match