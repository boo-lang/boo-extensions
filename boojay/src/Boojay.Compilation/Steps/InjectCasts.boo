namespace Boojay.Compilation.Steps

import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Steps
import Boo.Lang.PatternMatching

import Boojay.Compilation.TypeSystem

class InjectCasts(AbstractTransformerCompilerStep):
	
	_currentReturnType as IType
	
	override def Run():
		Visit CompileUnit
		
	override def EnterMethod(node as Method):
		_currentReturnType = bindingFor(node).ReturnType
		return true
		
	override def LeaveBinaryExpression(node as BinaryExpression):
		match node.Operator:
			
			case BinaryOperatorType.Assign:
				node.Right = checkCast(typeOf(node.Left), node.Right)
				
			case BinaryOperatorType.Or:
				checkOperands node
			
			case BinaryOperatorType.And:
				checkOperands node
				
			case BinaryOperatorType.TypeTest:
				node.Right = mapBoxedType(node.Right)
				
			otherwise:
				return
				
	def checkOperands(node as BinaryExpression):
		node.Right = checkCast(typeOf(node), node.Right)
		node.Left = checkCast(typeOf(node), node.Left)
				
	def mapBoxedType(e as TypeofExpression):
		boxedType = boxedTypeFor(bindingFor(e.Type)) 
		if boxedType is null: return e
		return CodeBuilder.CreateTypeofExpression(boxedType)
		
	override def LeaveMethodInvocationExpression(node as MethodInvocationExpression):
		m = optionalBindingFor(node.Target) as IMethodBase
		if m is null: return
		
		definition = definitionFor(m)
		parameterTypes = erasedParameterTypesFor(definition)
		for i in range(len(parameterTypes)):
			node.Arguments[i] = checkCast(parameterTypes[i], node.Arguments[i])
		
		returnType = m.CallableType.GetSignature().ReturnType
		if returnType is null:
			return
			
		ReplaceCurrentNode(checkCast(returnType, definition.CallableType.GetSignature().ReturnType, node))
			
	def erasedParameterTypesFor(m as IMethodBase):
		return array(erasureFor(p.Type) for p in m.GetParameters())
			
	override def LeaveReturnStatement(node as ReturnStatement):
		if node.Expression is null:
			return
		node.Expression = checkCast(_currentReturnType, node.Expression)
			
	def optionalBindingFor(node as Node):
		return typeSystem().GetOptionalEntity(node)
		
	def checkCast(expected as IType, e as Expression):
		actual = typeOf(e)
		return checkCast(expected, actual, e)
		
	def checkCast(expected as IType, actual as IType, e as Expression):
		
		if expected is actual:
			return e
		
		if isUnbox(expected, actual):
			return unbox(expected, e)
			
		if isBox(expected, actual):
			return box(actual, e)
		
		if actual.IsSubclassOf(expected):
			return e
			
		if isJavaLangObject(expected):
			return e
			
		return CodeBuilder.CreateCast(expected, e)
		
	def isBox(expected as IType, actual as IType):
		return actual.IsValueType and not expected.IsValueType
		
	def box(type as IType, e as Expression):
		boxedType = boxedTypeFor(type)
		assert boxedType is not null, type.ToString()
		return boxTo(boxedType, e)
		
	_boxedTypes as Hash
	
	def boxedTypeFor(type as IType) as System.Type:
		if _boxedTypes is null:
			_boxedTypes = {
				typeSystem().CharType: java.lang.Character,
				typeSystem().BoolType: java.lang.Boolean,
				typeSystem().IntType: java.lang.Integer,
			}
		return _boxedTypes[type]	
		
	def boxTo(type as System.Type, e as Expression):
		return CodeBuilder.CreateConstructorInvocation(firstConstructorFor(type), e)
		
	def firstConstructorFor(type as System.Type):
		return typeSystem().Map(type.GetConstructors()[0])
		
	def unbox(expected as IType, e as Expression):
		return CodeBuilder.CreateMethodInvocation(unboxMethodFor(expected), e)
		
	def unboxMethodFor(type as IType):
		return resolveRuntimeMethod("Unbox" + title(type.Name))
		
	def title(s as string):
		return s[:1].ToUpper() + s[1:]
		
	def isUnbox(expected as IType, actual as IType):
		return expected.IsValueType and not actual.IsValueType
				
	def typeSystem() as JavaTypeSystem:
		return self.TypeSystemServices