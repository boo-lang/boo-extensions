namespace Boojay.Compilation.Steps

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps

class NormalizeLiterals(AbstractTransformerCompilerStep):
	
	override def Run():
		Visit CompileUnit
	
	override def LeaveExpressionInterpolationExpression(node as ExpressionInterpolationExpression):
		code = [| java.lang.StringBuilder() |]
		for e in node.Expressions:
			code = [| $code.append($e) |]
		ReplaceCurrentNode([| $code.toString() |])
		
	override def LeaveListLiteralExpression(node as ListLiteralExpression):
		temp = uniqueReference()
		code = [| __eval__($temp = java.util.ArrayList($(len(node.Items)))) |]
		for item in node.Items:
			code.Arguments.Add([| $temp.add($item) |])
		code.Arguments.Add(temp)
		
		code.LexicalInfo = node.LexicalInfo
		ReplaceCurrentNode(code)
	