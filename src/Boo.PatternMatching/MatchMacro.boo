namespace Boo.PatternMatching

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast


# TODO: check for unreacheable patterns
class MatchMacro(AbstractAstMacro):
"""
Pattern matching facility:

	match <expression>:
		case <Pattern1>:
			<block1>
			.
			.
			.
		case <PatternN>:
			<blockN>
		otherwise:
			<blockOtherwise>

The following patterns are supported:
    
    Type() -- type test pattern
    Type(Property1: Pattern1, ...) -- object pattern
    Pattern1 | Pattern2 -- either pattern (NOT IMPLEMENTED)
    Pattern1 and condition -- constrained pattern  (NOT IMPLEMENTED)
    Pattern1 or condition -- constrained pattern  (NOT IMPLEMENTED)
    Pattern1, Pattern2 -- iteration pattern  (NOT IMPLEMENTED)
    x = Pattern -- variable binding
    x -- variable binding
    BinaryOperatorType.Assign -- constant pattern
    42 -- constant pattern
    "42" -- constant pattern
    null -- null test pattern
    
If no pattern matches MatchError is raised.
"""
	override def Expand(node as MacroStatement):
		assert 0 == len(node.Block.Statements)
		return MatchExpansion(Context, node).value

class MatchExpansion:
	
	node as MacroStatement
	expression as Expression
	matchValue as ReferenceExpression
	context as CompilerContext
	public final value as Statement
	
	def constructor(context as CompilerContext, node as MacroStatement):
		self.context = context
		self.node = node
		self.expression = node.Arguments[0]
		self.matchValue = newTemp(expression)
		self.value = expand()
		
	def expand():
		
		topLevel = expanded = expandCase(caseList(node)[0])
		for case in caseList(node)[1:]:
			caseExpansion = expandCase(case)
			continue if caseExpansion is null
			expanded.FalseBlock = caseExpansion.ToBlock()
			expanded = caseExpansion

		return null if topLevel is null
		
		expanded.FalseBlock = expandOtherwise()
		
		return [|
			block:
				$matchValue = $expression
				$topLevel
		|].Block
		
	def expandOtherwise():
		otherwise as MacroStatement = node["otherwise"]
		if otherwise is null: return defaultOtherwise()
		return expandOtherwise(otherwise)
		
	def expandOtherwise(node as MacroStatement):
		assert 0 == len(node.Arguments)
		return node.Block
		
	def defaultOtherwise():
		matchError = [| raise MatchError("'" + $(expression.ToCodeString()) + "' failed to match '" + $matchValue + "'") |]
		matchError.LexicalInfo = node.LexicalInfo
		return matchError.ToBlock()
		
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
			return expandBindPattern(reference, node.Block)
			
		capture = pattern as BinaryExpression
		if isCapture(capture):
			return expandCapturePattern(capture, node.Block)
			
		return expandValuePattern(pattern, node.Block)
		
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
		
	def expandBindPattern(node as ReferenceExpression, block as Block):
		return [| 
			if true:
				$node = $matchValue
				$block
		|]
		
	def newTemp(e as Expression):
		return ReferenceExpression(
				LexicalInfo: e.LexicalInfo,
				Name: "$match$${context.AllocIndex()}")

