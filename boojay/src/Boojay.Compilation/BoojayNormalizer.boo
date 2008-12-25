namespace Boojay.Compilation

import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Steps

class BoojayNormalizer(AbstractVisitorCompilerStep):
	
	override def Run():
		Visit CompileUnit
		
	override def LeaveBinaryExpression(node as BinaryExpression):
		if node.Operator != BinaryOperatorType.Assign: return
		
		node.Right = checkCast(expressionType(node.Left), node.Right)
		
	def checkCast(expected as IType, e as Expression):
		return e if expected.IsAssignableFrom(expressionType(e))
		return CodeBuilder.CreateCast(expected, e)
		
	def expressionType(e as Expression):
		return typeSystem().GetExpressionType(e)
		
	def typeSystem() as JavaTypeSystem:
		return self.TypeSystemServices