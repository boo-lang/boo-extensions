namespace Boo.Pegs

import Boo.Lang.PatternMatching
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

def expand(e as Expression) as Expression:
	match e:
		case ArrayLiteralExpression(Items: items):
			return expandArguments([| sequence() |], items)
			
		case ListLiteralExpression(Items: items):
			return expandArguments([| choice() |], items)
			
		case [| ++ $expression |]:
			return [| one_or_many($(expand(expression))) |]
			
		case [| -- $expression |]:
			return [| zero_or_many($(expand(expression))) |]
			
		case [| ~ $expression |]:
			return [| choice($(expand(expression)), empty()) |]
			
		case [| not $expression |]:
			return [| not_predicate($(expand(expression))) |]
			 
		case s=StringLiteralExpression():
			return [| terminal($s) |]
			
		case [| $l / $r |]:
			return [| choice($(expand(l)), $(expand(r))) |]
			
		case [| $l & $r |]:
			return [| predict($(expand(l)), $(expand(r))) |]
			
		case [| $l - $r |]:
			return [| char_range($(charFor(l)), $(charFor(r))) |]
			
		case block=BlockExpression():
			template = [| { context as PegContext | _ } |]
			block.Parameters = template.Parameters
			return ClosureExpander().Expand([| action($block) |])
			
		case MemberReferenceExpression():
			return e
			
		case reference=ReferenceExpression(Name: name):
			if name.StartsWith("@"):
				reference.Name = name[1:]
				return [| same_match($reference) |]
			return reference
			
		otherwise:
			return e
			
class ClosureExpander(DepthFirstTransformer):
	def Expand(node as Expression):
		return self.VisitNode(node)
		
	override def LeaveSpliceExpression(node as SpliceExpression):
		match node.Expression:
			case r=ReferenceExpression():
				mie = node.ParentNode as MethodInvocationExpression
				if mie is not null and mie.Target is node:
					mie.Arguments.Insert(0, [| context |])
					ReplaceCurrentNode(node.Expression)
					return
					
				ReplaceCurrentNode([| $r(context) |])
				
	override def OnReferenceExpression(node as ReferenceExpression):
		if not node.Name.StartsWith("@"): return
		
		node.Name = node.Name[1:]
		ReplaceCurrentNode([| context.RuleState.LastMatchFor($node) |])
		
def charFor(e as Expression):
	match e:
		case r=ReferenceExpression():
			return CharLiteralExpression(e.LexicalInfo, r.Name)
		case i=IntegerLiteralExpression():
			return CharLiteralExpression(e.LexicalInfo, cast(char, cast(int, char('0')) + i.Value))
			
def expandArguments(invocation as MethodInvocationExpression, args):
	for arg in args:
		invocation.Arguments.Add(expand(arg))
	return invocation

macro peg:
/*"""
Usage:

	peg MyGrammar:
	
		// sequence
		MyRule1 = E1, E2, EN 
		
		// choice
		MyRule2 = [Choice1, Choice2, ChoiceN] 
		MyRule3 = Choice1 / Choice2
		
		// repetition (one or many)
		MyRule4 = ++E
		
		// repetition (zero or many)
		MyRule5 = --E
		
		// optional
		MyRule6 = ~OptionalPrefix, Suffix
		
		// semantic action
		MyRule7 = { print $text }
		
Example:
		
	peg miniboo:
		Module = Spacing, ++Class, EndOfFile
		Class = CLASS, Identifier, Begin, ++Member, End
		Member = DEF, Identifier, LPAREN, RPAREN, Block
		Block = Begin, ++Statement, End
		Statement = Invocation
		Invocation = ++Expression
		Expression = Identifier / String
		String = "'", ++(not "'", any()), "'", Spacing 
		Identifier = ++[a-z, A-Z], OptionalSpacing
		Begin = ":", Spacing
		End = empty()
		Spacing = ++[' ', '\t', '\r', '\n']
		OptionalSpacing = ~Spacing
		CLASS = "class", Spacing
		DEF = "def", Spacing
		LPAREN = "(", OptionalSpacing
		RPAREN = ")", OptionalSpacing
		EndOfFile = not any()
"""*/
	
	rules = []
	for node in peg.Body.Statements:
		match node:
			case ExpressionStatement(
					Expression: BinaryExpression(
						Operator: BinaryOperatorType.Assign,
						Left: rule = ReferenceExpression(),
						Right: expression)):
				
				rules.Add((rule, expression))
	
	result = Block()
				
	# declare all rules
	for rule as ReferenceExpression, _ in rules:
		if rule.NodeType != NodeType.ReferenceExpression: continue
		decl = DeclarationStatement(
			Declaration(Name: rule.Name, Type: SimpleTypeReference("PegRule")),
			[| PegRule($(rule.Name)) |])
		result.Add(decl)
		
	# expand all the expressions
	for rule as ReferenceExpression, expression as Expression in rules:
		try:
			expansion = expand(expression)
			if rule.NodeType == NodeType.ReferenceExpression:
				result.Add([| $rule.Expression = $expansion |])
			else:
				result.Add([| $rule = $expansion |])
		except x:
			Context.Errors.Add(CompilerErrorFactory.MacroExpansionError(rule, x))
	
	return result
