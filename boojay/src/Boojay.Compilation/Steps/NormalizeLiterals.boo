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
		
	override def LeaveHashLiteralExpression(node as HashLiteralExpression):
		resultingHash = uniqueReference()
		code = [| __eval__($resultingHash = Boojay.Lang.Hash($(len(node.Items)))) |]
		for pair in node.Items:
			code.Arguments.Add([| $resultingHash.put($(pair.First), $(pair.Second)) |])
		code.Arguments.Add(resultingHash)
		ReplaceCurrentNode code
		
	override def LeaveListLiteralExpression(node as ListLiteralExpression):
		
		if AstUtil.IsListGenerator(node):
			return
			
		temp = uniqueReference()
		code = [| __eval__($temp = Boojay.Lang.List($(len(node.Items)))) |]
		for item in node.Items:
			code.Arguments.Add([| $temp.add($item) |])
		code.Arguments.Add(temp)
		
		code.LexicalInfo = node.LexicalInfo
		ReplaceCurrentNode(code)
	