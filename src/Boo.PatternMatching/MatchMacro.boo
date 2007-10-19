namespace Boo.PatternMatching

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

class MatchError(System.Exception):
	
	def constructor(msg as string):
		super(msg)

class MatchMacro(AbstractAstMacro):
	override def Expand(node as MacroStatement):
		return MatchExpander(Context).expand(node)

class MatchExpander:
	
	matchValue as ReferenceExpression
	context as CompilerContext
	
	def constructor(context as CompilerContext):
		self.context = context
		
	def expand(node as MacroStatement):
		
		expression = node.Arguments[0]
		matchValue = newTemp(expression)
		
		topLevel = expanded = expandCase(caseList(node)[0])
		for case in caseList(node)[1:]:
			expansion = expandCase(case)
			expanded.FalseBlock = expansion.ToBlock()
			expanded = expansion
			
		matchError = [| raise MatchError("'" + $(expression.ToCodeString()) + "' failed to match '" + $matchValue + "'") |]
		matchError.LexicalInfo = node.LexicalInfo
		
		expanded.FalseBlock = matchError.ToBlock()
		return [|
			block:
				$matchValue = $expression
				$topLevel
		|].Block
		
	def expandCase(node as MacroStatement):
		assert 1 == len(node.Arguments)
		pattern = node.Arguments[0]
		mie = pattern as MethodInvocationExpression
		if mie is not null:
			return expandObjectPattern(mie, node.Block)
		reference = pattern as ReferenceExpression
		if reference is not null:
			return expandIrrefutablePattern(reference, node.Block)
		raise CompilerError(pattern.LexicalInfo, "Unsupported pattern: '${pattern}'")
		
	def expandObjectPattern(node as MethodInvocationExpression, block as Block):
		condition = expandObjectPattern(matchValue, node)
		return [|
			if $condition:
				$block
		|]
		
	def expandObjectPattern(matchValue as Expression, node as MethodInvocationExpression) as Expression:
		
		typeName = cast(ReferenceExpression, node.Target).Name
	
		if len(node.NamedArguments) == 0 and len(node.Arguments) == 0:
			return [| $matchValue isa $(typeName) |]
			
		temp = newTemp(node)
		
		condition = [| ($temp = $matchValue as $(typeName)) is not null |]
		
		for member in node.Arguments:
			assert member isa ReferenceExpression, member.ToCodeString()
			memberRef = MemberReferenceExpression(member.LexicalInfo, temp.CloneNode(), member.ToString())
			condition = [| $condition and __eval__($member = $memberRef, true) |]  
			
		for member in node.NamedArguments:
			memberRef = MemberReferenceExpression(member.First.LexicalInfo, temp.CloneNode(), member.First.ToString())	
			variable = member.Second as ReferenceExpression
			if variable is not null and variable.NodeType == NodeType.ReferenceExpression:
				condition = [| $condition and __eval__($variable = $memberRef, true) |]
				continue
				
			nestedPattern = member.Second as MethodInvocationExpression
			if nestedPattern is not null:
				nestedCondition = expandObjectPattern(memberRef, nestedPattern)
				condition = [| $condition and $nestedCondition |]
				continue
				
			condition = [| $condition and ($memberRef == $(member.Second)) |]
		return condition
		
	def expandIrrefutablePattern(node as ReferenceExpression, block as Block):
		return [| 
			if true:
				$node = $matchValue
				$block
		|]
		
	def newTemp(e as Expression):
		return ReferenceExpression(
				LexicalInfo: e.LexicalInfo,
				Name: "$match$${context.AllocIndex()}")

class CaseMacro(AbstractAstMacro):
	override def Expand(node as MacroStatement):
		
		match = node.ParentNode.ParentNode as MacroStatement
		assert match.Name == "match"
		
		caseList(match).Add(node)
		
		return null
		
def caseList(node as MacroStatement) as List:
	list as List = node["caseList"]
	if list is null:
		node["caseList"] = list = []
	return list
