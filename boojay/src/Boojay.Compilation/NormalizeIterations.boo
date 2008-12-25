namespace Boojay.Compilation

import Boo.PatternMatching
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Steps

class NormalizeIterations(AbstractVisitorCompilerStep):
	
	_RuntimeServices_GetEnumerable as IMethod
	
	override def Run(): 
		Visit CompileUnit
		
	override def LeaveForStatement(node as ForStatement):
		
		if expressionType(node.Iterator).IsArray: return
		if isGetEnumerableInvocation(node.Iterator): return
		
		// For now always use RuntimeService.GetEnumerable to adapt
		// anything comes in
		
		node.Iterator = CodeBuilder.CreateMethodInvocation(RuntimeServices_GetEnumerable, node.Iterator)
		
	def isGetEnumerableInvocation(e as Expression):
		match e:
			case MethodInvocationExpression(Target: target):
				return typeSystem().GetOptionalEntity(target) is RuntimeServices_GetEnumerable
			otherwise:
				return false
				
	RuntimeServices_GetEnumerable:
		get:
			if _RuntimeServices_GetEnumerable is null:
				_RuntimeServices_GetEnumerable = typeSystem().Map(typeof(Boo.Lang.Runtime.RuntimeServices).GetMethod("GetEnumerable"))
			return _RuntimeServices_GetEnumerable
		
		
	def expressionType(e as Expression):
		return typeSystem().GetExpressionType(e)
		
	def typeSystem() as JavaTypeSystem:
		return self.TypeSystemServices