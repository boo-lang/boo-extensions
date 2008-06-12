namespace Boojay.Compilation

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps

class BoojaySemantics(AbstractTransformerCompilerStep):
	
	override def Run():
		Visit CompileUnit
	
	override def LeaveExpressionInterpolationExpression(node as ExpressionInterpolationExpression):
		code = [| java.lang.StringBuilder() |]
		for e in node.Expressions:
			code = [| $code.append($e) |]
		ReplaceCurrentNode([| $code.toString() |])
	