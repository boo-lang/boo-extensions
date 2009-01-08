namespace Boojay.Compilation.Steps

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Ast

def resolveRuntimeMethod(methodName as string):
	return resolveMethod(typeSystem().RuntimeServicesType, methodName)
	
def resolveMethod(type as IType, name as string):
	return nameResolutionService().ResolveMethod(type, name)
	
def entity(node as Node):
	return typeSystem().GetEntity(node)
	
def typeOf(e as Expression):
	return typeSystem().GetExpressionType(e)
	
def typeSystem():
	return context().TypeSystemServices
	
def nameResolutionService():
	return context().NameResolutionService
	
def context():
	return CompilerContext.Current
	
def uniqueName():
	return "$" + context().AllocIndex()
		
