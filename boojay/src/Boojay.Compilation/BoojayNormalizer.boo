namespace Boojay.Compilation

import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Steps

class BoojayNormalizer(AbstractVisitorCompilerStep):
	
	_currentReturnType as IType
	
	override def Run():
		Visit CompileUnit
		
	override def EnterMethod(node as Method):
		_currentReturnType = GetEntity(node).ReturnType
		return true
		
	override def LeaveBinaryExpression(node as BinaryExpression):
		if node.Operator != BinaryOperatorType.Assign: return
		
		node.Right = checkCast(expressionType(node.Left), node.Right)
		
	override def LeaveMethodInvocationExpression(node as MethodInvocationExpression):
		m = optionalEntity(node.Target) as IMethodBase
		if m is null: return
		
		parameters = m.GetParameters()
		for i in range(len(parameters)):
			node.Arguments[i] = checkCast(parameters[i].Type, node.Arguments[i])
			
	override def LeaveReturnStatement(node as ReturnStatement):
		if node.Expression is null: return
		
		node.Expression = checkCast(_currentReturnType, node.Expression)
			
	def optionalEntity(node as Node):
		return typeSystem().GetOptionalEntity(node)
		
	def checkCast(expected as IType, e as Expression):
		actual = expressionType(e)
		
		if isUnbox(expected, actual):
			return unbox(expected, e)
			
		if isBox(expected, actual):
			return box(actual, e)
		
		if expected.IsAssignableFrom(actual):
			return e
			
		return CodeBuilder.CreateCast(expected, e)
		
	def isBox(expected as IType, actual as IType):
		return actual.IsValueType and not expected.IsValueType
		
	def box(type as IType, e as Expression):
		if type is typeSystem().CharType:
			return boxChar(e)
		raise type.ToString()
		
	def boxChar(e as Expression):
		return CodeBuilder.CreateConstructorInvocation(java_lang_Character, e)
		
	java_lang_Character:
		get:
			return typeSystem().Map(typeof(java.lang.Character).GetConstructors()[0])
		
	def unbox(expected as IType, e as Expression):
		return CodeBuilder.CreateMethodInvocation(unboxMethodFor(expected), e)
		
	def unboxMethodFor(type as IType):
		return resolveRuntimeMethod("Unbox" + title(type.Name))
		
	def resolveRuntimeMethod(methodName as string):
		return resolveMethod(typeSystem().RuntimeServicesType, methodName)
		
	def resolveMethod(type as IType, name as string):
		return NameResolutionService.ResolveMethod(type, name)
		
	def title(s as string):
		return s[:1].ToUpper() + s[1:]
		
	def isUnbox(expected as IType, actual as IType):
		return expected.IsValueType and not actual.IsValueType
		
	def expressionType(e as Expression):
		return typeSystem().GetExpressionType(e)
		
	def typeSystem() as JavaTypeSystem:
		return self.TypeSystemServices