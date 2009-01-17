namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler.TypeSystem

class GenericMethodDefinitionFinder:
	
	_method as IMethod
	_signature as (IType)
	_typeInfo as IConstructedTypeInfo
	_typeDefinition as IType
	
	def constructor(method as IMethod):
		_method = method
		_signature = array(p.Type for p in method.GetParameters())
		_typeInfo =  method.DeclaringType.ConstructedInfo
		_typeDefinition = _typeInfo.GenericDefinition
		
	def find():
		for candidate in candidates():
			if sameSignatureAs(candidate):
				return candidate
				
	def candidates():
		if _method isa IConstructor:
			return _typeDefinition.GetConstructors()
		
		found = []
		assert _typeDefinition.Resolve(found, _method.Name, EntityType.Method), _method.Name
		return array(IMethodBase, found)
		
	def sameSignatureAs(candidate as IMethod):
		parameters = candidate.GetParameters()
		if len(parameters) != len(_signature):
			return false
			
		actual = constructedParameterTypeFor(p) for p in parameters
		for expectedType, actualType in zip(_signature, actual):
			if expectedType is not actualType:
				return false
				
		return true
		
	def constructedParameterTypeFor(p as IParameter):
		type = (p.Type as ExternalType).ActualType
		if type.IsGenericParameter:
			return _typeInfo.GenericArguments[type.GenericParameterPosition]
		return p.Type