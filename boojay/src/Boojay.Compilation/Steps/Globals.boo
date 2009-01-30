namespace Boojay.Compilation.Steps

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

def resolveRuntimeMethod(methodName as string):
	return resolveMethod(typeSystem().RuntimeServicesType, methodName)
	
def resolveMethod(type as IType, name as string):
	return nameResolutionService().ResolveMethod(type, name)
	
def bindingFor(node as Node):
	return typeSystem().GetEntity(node)
	
def bindingFor(node as Method) as IMethod:
	return typeSystem().GetEntity(node)
	
def erasureFor(type as IType):
	if type isa IGenericParameter:
		return typeSystem().ObjectType
	
#	genericInstance = type.ConstructedInfo
#	if genericInstance is not null:
#		return genericInstance.GenericDefinition
		
	return type
		
def isJavaLangObject(type as IType):
	if typeSystem().IsSystemObject(type):
		return true
	return type is Null.Default
	
def definitionFor(m as IMethodBase):
	if m.DeclaringType.ConstructedInfo is null:
		return m
	return Boojay.Compilation.TypeSystem.GenericMethodDefinitionFinder(m).find()

def typeOf(e as Expression) as IType:
	match e:
		case [| null |]:
			return Null.Default
		case [| true |] | [| false |]:
			return typeSystem().BoolType
		otherwise:
			return typeSystem().GetExpressionType(e)

def typeSystem():
	return context().TypeSystemServices
	
def nameResolutionService():
	return context().NameResolutionService
	
def context():
	return CompilerContext.Current
	
def uniqueName():
	return "$" + context().AllocIndex()
	
def uniqueReference():
	return ReferenceExpression(uniqueName())
		
