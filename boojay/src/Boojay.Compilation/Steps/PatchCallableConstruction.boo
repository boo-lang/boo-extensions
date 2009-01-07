namespace Boojay.Compilation.Steps


import Boo.Lang.PatternMatching
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Steps

class PatchCallableConstruction(AbstractTransformerCompilerStep):
	
	_currentClass as ClassDefinition

	override def Run():
		if len(Errors) > 0:
			return
		Visit CompileUnit
		
	override def EnterClassDefinition(node as ClassDefinition):
		_currentClass = node
		return true
			
	override def LeaveMethodInvocationExpression(node as MethodInvocationExpression):
		match node:
			case [| $ctor(null, __addressof__($method)) |]:
				ctorEntity as IMethodBase = entity(ctor)
				ReplaceCurrentNode(newCallableConstruction(ctorEntity.DeclaringType, entity(method)))
			otherwise:
				pass
				
	def newCallableConstruction(callableType as ICallableType, method as IMethod):
		concreteType = CodeBuilder.CreateClass(uniqueName(), TypeMemberModifiers.Private)
		concreteType.AddBaseType(callableType)
		concreteType.AddConstructor().Body.Add(CodeBuilder.CreateSuperConstructorInvocation(callableType))
		concreteType.ClassDefinition.Members.Add(implementInvokeFor(resolveMethod(callableType, "Invoke"), method))
		addToCurrentClass(concreteType.ClassDefinition)
		return CodeBuilder.CreateConstructorInvocation(concreteType.ClassDefinition)
		
	def implementInvokeFor(prototype as IMethod, method as IMethod):
		
		invoke = CodeBuilder.CreateMethodFromPrototype(prototype, TypeMemberModifiers.Public | TypeMemberModifiers.Virtual)
		
		invocation = CodeBuilder.CreateMethodInvocation(method)
		for p in invoke.Parameters:
			invocation.Arguments.Add(CodeBuilder.CreateReference(p))
		invoke.Body.Add(ReturnStatement(invocation))
		
		return invoke
		
	def addToCurrentClass(member as TypeMember):
		_currentClass.Members.Add(member)
	
	def uniqueName():
		return "$" + Context.AllocIndex()