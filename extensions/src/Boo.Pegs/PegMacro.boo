namespace Boo.Pegs

import Boo.PatternMatching
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

def expand(e as Expression) as Expression:
	match e:
		case ArrayLiteralExpression(Items: items):
			return expandArguments([| sequence() |], items)
			
		case ListLiteralExpression(Items: items):
			return expandArguments([| choice() |], items)
			
		case UnaryExpression(Operator: UnaryOperatorType.Increment, Operand: expression):
			return [| one_or_many($(expand(expression))) |]
			
		case UnaryExpression(Operator: UnaryOperatorType.Decrement, Operand: expression):
			return [| zero_or_many($(expand(expression))) |]
			
		case UnaryExpression(Operator: UnaryOperatorType.OnesComplement, Operand: expression):
			return [| choice($(expand(expression)), empty()) |]
			
		case UnaryExpression(Operator: UnaryOperatorType.LogicalNot, Operand: expression):
			return [| not_predicate($(expand(expression))) |]
			 
		case s=StringLiteralExpression():
			return [| terminal($s) |]
			
		case BinaryExpression(
				Operator: BinaryOperatorType.BitwiseOr,
				Left: l,
				Right: r):
			
			return [| choice($(expand(l)), $(expand(r))) |]
			
		case BinaryExpression(
				Operator: BinaryOperatorType.BitwiseAnd,
				Left: l,
				Right: r):
					
			return [| predict($(expand(l)), $(expand(r))) |]
			
		case BinaryExpression(
				Operator: BinaryOperatorType.Subtraction,
				Left: l=ReferenceExpression(),
				Right: r=ReferenceExpression()):
			return [| char_range($(charFor(l)), $(charFor(r))) |]
			
		case block=BlockExpression():
			template = [| { context as PegContext | _ } |]
			block.Parameters = template.Parameters
			return SpliceExpander().Expand([| action($block) |])
			
		case reference=ReferenceExpression(Name: name):
			if name.StartsWith("@"):
				reference.Name = name[1:]
				return [| same_match($reference) |]
			return reference
			
		otherwise:
			return e
			
class SpliceExpander(DepthFirstTransformer):
	def Expand(node as Expression):
		return self.VisitNode(node)
		
	override def LeaveSpliceExpression(node as SpliceExpression):
		match node.Expression:
			case function=ReferenceExpression():
				mie = node.ParentNode as MethodInvocationExpression
				if mie is not null and mie.Target is node:
					mie.Arguments.Insert(0, [| context |])
					ReplaceCurrentNode(node.Expression)
				else:
					ReplaceCurrentNode([| $function(context) |])
			
def charFor(e as ReferenceExpression):
	return CharLiteralExpression(e.LexicalInfo, e.Name)
			
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
		MyRule3 = Choice1 | Choice2
		
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
		Expression = Identifier | String
		String = "'", ++(not "'"), "'", Spacing 
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
	for node in peg.Block.Statements:
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
		decl = DeclarationStatement(
			Declaration(Name: rule.Name, Type: SimpleTypeReference("PegRule")),
			[| PegRule() |])
		result.Add(decl)
		
	# expand all the expressions
	for rule as ReferenceExpression, expression as Expression in rules:
		try:
			result.Add([| $rule.Expression = $(expand(expression)) |])
		except x:
			Context.Errors.Add(CompilerErrorFactory.MacroExpansionError(rule, x))
	
	return result
