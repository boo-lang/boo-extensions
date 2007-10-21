namespace Boo.PatternMatching

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

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
			continue if expansion is null
			expanded.FalseBlock = expansion.ToBlock()
			expanded = expansion

		return null if topLevel is null
					
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
			
		memberRef = pattern as MemberReferenceExpression
		if memberRef is not null:
			return expandValuePattern(memberRef, node.Block)
			
		reference = pattern as ReferenceExpression
		if reference is not null:
			return expandIrrefutablePattern(reference, node.Block)
			
		capture = pattern as BinaryExpression
		if isCapture(capture):
			return expandCapturePattern(capture, node.Block)	
		
		context.Errors.Add(CompilerError(pattern.LexicalInfo, "Unsupported pattern: '${pattern}'"))
		
	def isCapture(node as BinaryExpression):
		if node is null: return false
		if node.Operator != BinaryOperatorType.Assign: return false
		return node.Left isa ReferenceExpression and node.Right isa MethodInvocationExpression
		
	def expandValuePattern(node as Expression, block as Block):
		return [|
			if $matchValue == $node:
				$block
		|]
		
	def expandCapturePattern(node as BinaryExpression, block as Block):
		condition = expandObjectPattern(matchValue, node.Left, node.Right)
		return [|
			if $condition:
				$block
		|] 
		
	def expandObjectPattern(node as MethodInvocationExpression, block as Block):
		condition = expandObjectPattern(matchValue, node)
		return [|
			if $condition:
				$block
		|]
		
	def expandObjectPattern(matchValue as Expression, node as MethodInvocationExpression) as Expression:
	
		if len(node.NamedArguments) == 0 and len(node.Arguments) == 0:
			return [| $matchValue isa $(typeName(node)) |]
			 
		return expandObjectPattern(matchValue, newTemp(node), node)
		
	def expandObjectPattern(matchValue as Expression, temp as ReferenceExpression, node as MethodInvocationExpression) as Expression:
		
		condition = [| ($matchValue isa $(typeName(node))) and __eval__($temp = cast($(typeName(node)), $matchValue), true) |]
		condition.LexicalInfo = node.LexicalInfo
		
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
		
	def typeName(node as MethodInvocationExpression):
		return cast(ReferenceExpression, node.Target).Name
		
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

