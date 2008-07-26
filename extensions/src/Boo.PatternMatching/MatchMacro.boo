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
    (Pattern1, Pattern2) -- fixed size iteration pattern
    [Pattern1, Pattern2] -- arbitrary size iteration pattern (NOT IMPLEMENTED)
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
	context as CompilerContext
	public final value as Statement
	
	def constructor(context as CompilerContext, node as MacroStatement):
		self.context = context
		self.node = node
		self.expression = node.Arguments[0]
		self.value = expand(newTemp(expression))
		
	def expand(matchValue as Expression):
		
		topLevel = expanded = expandCase(matchValue, caseList(node)[0])
		for case in caseList(node)[1:]:
			caseExpansion = expandCase(matchValue, case)
			expanded.FalseBlock = caseExpansion.ToBlock()
			expanded = caseExpansion		
		expanded.FalseBlock = expandOtherwise(matchValue)
		
		return [|
			block:
				$matchValue = $expression
				$topLevel
		|].Block
		
	def expandOtherwise(matchValue as Expression):
		otherwise as MacroStatement = node["otherwise"]
		if otherwise is null: return defaultOtherwise(matchValue)
		return expandOtherwise(otherwise)
		
	def expandOtherwise(node as MacroStatement):
		assert 0 == len(node.Arguments)
		return node.Block
		
	def defaultOtherwise(matchValue as Expression):
		matchError = [| raise MatchError("'" + $(expression.ToCodeString()) + "' failed to match '" + $matchValue + "'") |]
		matchError.LexicalInfo = node.LexicalInfo
		return matchError.ToBlock()
		
	def expandCase(matchValue as Expression, node as MacroStatement):
		assert 1 == len(node.Arguments)
		pattern = node.Arguments[0]
		condition = expandPattern(matchValue, pattern)
		return [| 
			if $condition:
				$(node.Block)
		|]
		
	def expandPattern(matchValue as Expression, pattern as Expression) as Expression:
		mie = pattern as MethodInvocationExpression
		if mie is not null:
			return expandObjectPattern(matchValue, mie)
			
		memberRef = pattern as MemberReferenceExpression
		if memberRef is not null:
			return expandValuePattern(matchValue, memberRef)
			
		reference = pattern as ReferenceExpression
		if reference is not null:
			return expandBindPattern(matchValue, reference)
			
		quasiquote = pattern as QuasiquoteExpression
		if quasiquote is not null:
			return expandQuasiquotePattern(matchValue, quasiquote)
			
		capture = pattern as BinaryExpression
		if isCapture(capture):
			return expandCapturePattern(matchValue, capture)
			
		fixedSize = pattern as ArrayLiteralExpression
		if fixedSize is not null:
			return expandFixedSizePattern(matchValue, fixedSize)
			
		return expandValuePattern(matchValue, pattern)
		
	def isCapture(node as BinaryExpression):
		if node is null: return false
		if node.Operator != BinaryOperatorType.Assign: return false
		return node.Left isa ReferenceExpression and node.Right isa MethodInvocationExpression
		
	def expandBindPattern(matchValue as Expression, node as ReferenceExpression):
		return [| __eval__($node = $matchValue, true) |]
		
	def expandValuePattern(matchValue as Expression, node as Expression):
		return [| $matchValue == $node |]
		
	def expandCapturePattern(matchValue as Expression, node as BinaryExpression):
		return expandObjectPattern(matchValue, node.Left, node.Right)
		
	def expandObjectPattern(matchValue as Expression, node as MethodInvocationExpression) as Expression:
	
		if len(node.NamedArguments) == 0 and len(node.Arguments) == 0:
			return [| $matchValue isa $(typeRef(node)) |]
			 
		return expandObjectPattern(matchValue, newTemp(node), node)
		
	def expandObjectPattern(matchValue as Expression, temp as ReferenceExpression, node as MethodInvocationExpression) as Expression:
		
		condition = [| ($matchValue isa $(typeRef(node))) and __eval__($temp = cast($(typeRef(node)), $matchValue), true) |]
		condition.LexicalInfo = node.LexicalInfo
		
		for member in node.Arguments:
			assert member isa ReferenceExpression, "Invalid argument '${member}' in pattern '${node}'."
			memberRef = MemberReferenceExpression(member.LexicalInfo, temp.CloneNode(), member.ToString())
			condition = [| $condition and __eval__($member = $memberRef, true) |]  
			
		for member in node.NamedArguments:
			namedArgCondition = expandMemberPattern(temp.CloneNode(), member)
			condition = [| $condition and $namedArgCondition |]
			
		return condition
	
	class QuasiquotePatternBuilder(DepthFirstVisitor):
		
		_expansion as MatchExpansion
		_pattern as Expression
		
		def constructor(expansion as MatchExpansion):
			_expansion = expansion
		
		def build(node as QuasiquoteExpression):
			return expand(node.Node)
			
		def expand(node as Node):
			node.Accept(self)
			expansion = _pattern
			_pattern = null
			assert expansion is not null, "Unsupported pattern '${node}'"
			return expansion
			
		override def OnSpliceExpression(node as SpliceExpression):
			_pattern = node.Expression
			
		override def OnSpliceTypeReference(node as SpliceTypeReference):
			_pattern = node.Expression
			
		override def OnTryCastExpression(node as TryCastExpression):
			_pattern = [| TryCastExpression(Target: $(expand(node.Target)), Type: $(expand(node.Type))) |]
			
		override def OnMethodInvocationExpression(node as MethodInvocationExpression):
			assert 0 == len(node.Arguments), "Unsupported pattern '${node}'"
			_pattern = [| MethodInvocationExpression(Target: $(expand(node.Target))) |]
			
		override def OnUnaryExpression(node as UnaryExpression):
			_pattern = [| UnaryExpression(Operator: UnaryOperatorType.$(node.Operator.ToString()), Operand: $(expand(node.Operand))) |]
			
		override def OnBinaryExpression(node as BinaryExpression):
			_pattern = [| BinaryExpression(Operator: BinaryOperatorType.$(node.Operator.ToString()), Left: $(expand(node.Left)), Right: $(expand(node.Right))) |]
		
		override def OnReferenceExpression(node as ReferenceExpression):
			_pattern = [| ReferenceExpression(Name: $(node.Name)) |]
			
	def objectPatternFor(node as QuasiquoteExpression):
		return QuasiquotePatternBuilder(self).build(node)
		
	def expandQuasiquotePattern(matchValue as Expression, node as QuasiquoteExpression) as Expression:
		return expandObjectPattern(matchValue, objectPatternFor(node))
		
	def expandMemberPattern(matchValue as Expression, member as ExpressionPair):
		memberRef = MemberReferenceExpression(member.First.LexicalInfo, matchValue, member.First.ToString())	
		return expandPattern(memberRef, member.Second)
		
	def expandFixedSizePattern(matchValue as Expression, pattern as ArrayLiteralExpression):
		condition = [| $(len(pattern.Items)) == len($matchValue) |]
		i = 0
		for item in pattern.Items:
			itemValue = [| $matchValue[$i] |]
			itemPattern = expandPattern(itemValue, item)
			condition = [| $condition and $itemPattern |]
			++i
		return condition
		
	def typeRef(node as MethodInvocationExpression):
		return node.Target
		
	def newTemp(e as Expression):
		return ReferenceExpression(
				LexicalInfo: e.LexicalInfo,
				Name: "$match$${context.AllocIndex()}")

