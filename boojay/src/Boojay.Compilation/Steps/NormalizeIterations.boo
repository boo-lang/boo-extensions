namespace Boojay.Compilation.Steps

import Boo.Lang.PatternMatching
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Steps

import Boojay.Compilation.TypeSystem

class NormalizeIterations(AbstractVisitorCompilerStep):
	
	_RuntimeServices_GetEnumerable as IMethod
	
	override def Run(): 
		Visit CompileUnit
		
	override def LeaveForStatement(node as ForStatement):
		
		if typeOf(node.Iterator).IsArray: return
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
				_RuntimeServices_GetEnumerable = resolveMethod(Boojay.Lang.RuntimeServices, "GetEnumerable")
			return _RuntimeServices_GetEnumerable
			
	def resolveMethod(type as System.Type, methodName as string):
		return NameResolutionService.ResolveMethod(typeSystem().Map(type), methodName)
		
	def typeOf(e as Expression):
		return typeSystem().GetExpressionType(e)
		
	def typeSystem() as JavaTypeSystem:
		return self.TypeSystemServices