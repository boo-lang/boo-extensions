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
				ReplaceCurrentNode(newCallableConstruction(declaringTypeOf(ctor), entity(method)))
			case [| $ctor($target, __addressof__($method)) |]:
				ReplaceCurrentNode(newCallableConstructionWithTarget(target, declaringTypeOf(ctor), entity(method)))
			otherwise:
				pass
				
	def declaringTypeOf(reference as Expression):
		return cast(IMember, entity(reference)).DeclaringType
				
	def newCallableConstruction(callableType as ICallableType, method as IMethod):
		return newConcreteCallableInstance(null, callableType, method)
		
	def newCallableConstructionWithTarget(target as Expression, callableType as ICallableType, method as IMethod):
		return newConcreteCallableInstance(target, callableType, method)
		
	def newConcreteCallableInstance(target as Expression, callableType as ICallableType, method as IMethod):
		concreteType = CodeBuilder.CreateClass(uniqueName(), TypeMemberModifiers.Private)
		concreteType.AddBaseType(callableType)
		targetField = concreteType.AddField("_target", method.DeclaringType) if target is not null
		ctor = concreteType.AddConstructor()
		ctor.Body.Add(CodeBuilder.CreateSuperConstructorInvocation(callableType))
		concreteType.ClassDefinition.Members.Add(implementInvokeFor(targetField, resolveMethod(callableType, "Invoke"), method))
		ctorInvocation = CodeBuilder.CreateConstructorInvocation(ctor.Entity as IConstructor)
		addToCurrentClass(concreteType.ClassDefinition)
		
		if target is null:
			return ctorInvocation
		
		targetParameter = ctor.AddParameter("target", entity(targetField.Type))
		ctor.Body.Add(
			CodeBuilder.CreateAssignment(
				CodeBuilder.CreateReference(targetField),
				CodeBuilder.CreateReference(targetParameter)))
		ctorInvocation.Arguments.Add(target)
		return ctorInvocation
		
		
	def implementInvokeFor(target as Field, prototype as IMethod, method as IMethod):
		
		invoke = CodeBuilder.CreateMethodFromPrototype(prototype, TypeMemberModifiers.Public | TypeMemberModifiers.Virtual)
		
		if target is null:
			invocation = CodeBuilder.CreateMethodInvocation(method)
		else:
			invocation = CodeBuilder.CreateMethodInvocation(CodeBuilder.CreateReference(target), method)
			
		for p in invoke.Parameters:
			invocation.Arguments.Add(CodeBuilder.CreateReference(p))
		
		if prototype.ReturnType is not typeSystem().VoidType:
			invoke.Body.Add(ReturnStatement(invocation))
		else:
			invoke.Body.Add(invocation)
			
		return invoke
		
	def addToCurrentClass(member as TypeMember):
		_currentClass.Members.Add(member)
	
	def uniqueName():
		return "$" + Context.AllocIndex()