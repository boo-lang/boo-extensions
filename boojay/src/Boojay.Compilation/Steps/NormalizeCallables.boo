namespace Boojay.Compilation.Steps

import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Steps

class NormalizeCallables(AbstractTransformerCompilerStep):
	
	_currentClass as ClassDefinition
	
	override def Run():
		if len(Errors) > 0:
			return
		Visit CompileUnit
		
	override def EnterClassDefinition(node as ClassDefinition):
		if node.Name == "CompilerGeneratedExtensions":
			RemoveCurrentNode()
			return false
			
		_currentClass = node
		return true
		
	override def LeaveClassDefinition(node as ClassDefinition):
		callableType = bindingFor(node) as InternalCallableType
		if callableType is null:
			return
		normalize callableType
		
	def normalize(type as InternalCallableType):
		typeDef = type.TypeDefinition
		typeDef.Members.Remove(typeDef.Members["BeginInvoke"])
		typeDef.Members.Remove(typeDef.Members["EndInvoke"])
		
		ctor = typeDef.GetConstructor(0)
		ctor.Parameters.Clear()
		ctor.Body.Add(CodeBuilder.CreateSuperConstructorInvocation(type.BaseType))

		invoke = typeDef.Members["Invoke"]
		invoke.Modifiers = TypeMemberModifiers.Public | TypeMemberModifiers.Abstract
		
		typeDef.Modifiers &= ~TypeMemberModifiers.Final
		typeDef.Modifiers |= TypeMemberModifiers.Abstract
