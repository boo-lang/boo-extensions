namespace Boojay.Compilation.TypeSystem

import Boo.Lang.Compiler.TypeSystem


class BeanPropertyFinder:
	
	_properties = {}
	
	def constructor(entities as IEntity*):
		for entity in entities:
			if entity.EntityType == EntityType.Method:
				if isGetter(entity):
					processGetter entity
				elif isSetter(entity):
					processSetter entity
					
	def findAll():
		occurrences = {}
		for p as IProperty in _properties.Values:
			count as int = occurrences[p.Name] or 0
			occurrences[p.Name] = count + 1
			
		for p as IProperty in _properties.Values:
			count = occurrences[p.Name]
			yield p if count == 1
					
	def isGetter(entity as IMethod):
		return hasCamelCasePrefix(entity, "get") and 0 == len(entity.GetParameters())
	
	def isSetter(entity as IMethod):
		return hasCamelCasePrefix(entity, "set") and 1 == len(entity.GetParameters())
		
	private def hasCamelCasePrefix(entity as IEntity, prefix as string):
		name = entity.Name
		if name.Length <= prefix.Length + 1: return false
		return name.StartsWith(prefix) and char.IsUpper(name[prefix.Length])

	private def processGetter(method as IMethod):
		beanPropertyFor(method, method.ReturnType).Getter = method

	private def processSetter(method as IMethod):
		beanPropertyFor(method, method.GetParameters()[-1].Type).Setter = method

	private def beanPropertyFor(method as IMethod, propertyType as IType):
		propertyName = method.Name[3:]
		propertyKey = (propertyName, propertyType)
		beanProperty as BeanProperty = _properties[propertyKey]
		if beanProperty is null:
			beanProperty = BeanProperty(method.DeclaringType, propertyName, propertyType)
			_properties[propertyKey] = beanProperty
		return beanProperty

internal class BeanProperty(IProperty):

	[getter(DeclaringType)] _declaringType as IType
	[getter(Name)] _name as string
	[getter(Type)] _type as IType
	_getter as IMethod
	_setter as IMethod
	
	def constructor(declaringType as IType, name as string, type as IType):
		_declaringType = declaringType
		_name = char.ToLower(name[0]) + name[1:]
		_type = type

	Getter:
		set:
			assert _getter is null
			_getter = value
			
	Setter:
		set:
			assert _setter is null
			_setter = value
			
	FullName:
		get: return Name

	EntityType:
		get: return EntityType.Property
			
	def IsDefined(attributeType as IType):
		return false
	
	IsDuckTyped:
		get: return false
		
	IsStatic:
		get: return AnyAccessor().IsStatic
		
	IsPublic:
		get: return AnyAccessor().IsPublic
		
	IsProtected:
		get: return AnyAccessor().IsProtected
		
	IsInternal:
		get: return AnyAccessor().IsInternal
		
	IsPrivate:
		get: return AnyAccessor().IsPrivate
		
	def GetParameters():
		return array(IParameter, 0)
		
	AcceptVarArgs:
		get: return false
		
	IsExtension:
		get: return false
		
	IsBooExtension:
		get: return false

	IsClrExtension:
		get: return false
		
	def GetGetMethod():
		return _getter

	def GetSetMethod():
		return _setter
	
	def AnyAccessor():
		return GetGetMethod() or GetSetMethod()
		
	override def ToString():
		return "${Name} as ${Type}"
