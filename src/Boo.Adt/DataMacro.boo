namespace Boo.Adt

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro data:
"""
Produces a complete data type hierarchy from a declaration.

All the types produced are immutable (unless instructed otherwise) and have
meaningful implementations for Equals, GetHashCode and ToString.

Usage:

	data Expression = Const(Value as int) | Add(Left as Expression, Right as Expression)
	
	
	data SingleValue(Value as int)
	
	
	data TypeWithMutableField(@MutableValue as int) // @ makes the field mutable
"""
	
	DataMacroExpansion(data)

class DataMacroExpansion:
	
	_module as TypeDefinition
	_baseType as TypeDefinition
	
	def constructor(node as MacroStatement):
		
		assert 1 == len(node.Arguments)
		_module = enclosingModule(node)
		
		match node.Arguments[0]:
			case [| $left = $right |]:
				_baseType = createBaseType(left)
				expandDataConstructors(right)
				
			case ctor=MethodInvocationExpression():
				_baseType = [|
					class object:
						pass
				|]
				expandDataConstructor(ctor)
				
		
	def createBaseType(node as Expression):
		type = baseTypeForExpression(node)
		registerType(type)
		return type
		
	def abstractType(name as string):
		type = [|
			partial abstract class $name:
				pass
		|]
		return type
		
	def baseTypeForExpression(node as Expression):
		match node:
			case ReferenceExpression(Name: name):
				return abstractType(name)
				
			case [| $(ReferenceExpression(Name: name)) < $(ReferenceExpression(Name: baseType)) |]:
				type = [|
					partial abstract class $name($baseType):
						pass
				|]
				return type
				
			case mie=MethodInvocationExpression(Target: ReferenceExpression(Name: name)):
				type = abstractType(name)
				fields = fieldsFrom(mie)
				type.Members.Extend(fields)
				type.Members.Add(constructorForFields(fields))
				return type
				
			case gre=SlicingExpression(
						Target: ReferenceExpression(Name: name)):
				type = [|
					partial abstract class $name[of T]:
						pass
				|]
				type.GenericParameters.Clear()
				for index in gre.Indices:
					match index:
						case Slice(
							Begin: ReferenceExpression(Name: name),
							End: null,
							Step: null):
							type.GenericParameters.Add(
								GenericParameterDeclaration(Name: name))
				return type
			
		
	def expandDataConstructors(node as Expression):
		match node:
			case [| $left | $right |]:
				expandDataConstructors(left)
				expandDataConstructors(right)
			case MethodInvocationExpression():
				expandDataConstructor(node)
				
	def expandDataConstructor(node as MethodInvocationExpression):
		type = dataConstructorTypeForExpression(node.Target)
		type.LexicalInfo = node.LexicalInfo
		type.Members.Extend(fields = fieldsFrom(node))
		type.Members.Add(toStringForType(type))
		type.Members.Add(equalsForType(type)) 
		
		ctor = constructorForFields(fields)
		if len(_baseType.Members):
			superInvocation = [| super() |]
			i = 0
			for field as Field in fieldsOf(_baseType):
				ctor.Parameters.Insert(i++, 
					ParameterDeclaration(Name: field.Name, Type: field.Type))
				superInvocation.Arguments.Add(ReferenceExpression(field.Name))
			ctor.Body.Insert(0, superInvocation)
		type.Members.Add(ctor)
		
		registerType(type)
		
	def dataConstructorTypeForExpression(node as Expression):
		match node:
			case ReferenceExpression(Name: name):
				type = [|
					partial class $name($_baseType):
						pass
				|]
				for arg in _baseType.GenericParameters:
					type.GenericParameters.Add(
								GenericParameterDeclaration(Name: arg.Name))
				return type
						
		
	def equalsForType(type as TypeDefinition):
		
		allFields = List(fieldsIncludingBaseType(type))
		if len(allFields) == 0:
			method = [|
				override def Equals(o):
					if o is null: return false
					return self.GetType() is o.GetType()
			|]
			return method
			
		method = [|
			override def Equals(o):
				if o is null: return false
				if self.GetType() is not o.GetType(): return false
				other as $type = o
		|]
	
		for field as Field in allFields:
			comparison = [|
				if self.$(field.Name) != other.$(field.Name):
					return false
			|]
			method.Body.Add(comparison)
			
		method.Body.Add([| return true |])
		return method
		
	def toStringForType(type as TypeDefinition):
		expression = ExpressionInterpolationExpression()
		items = expression.Expressions
		items.Add([| $("${type.Name}(") |])
		
		comma = false
		for field as Field in fieldsIncludingBaseType(type):
			if comma: items.Add([| ", " |])
			items.Add([| self.$(field.Name) |])
			comma = true
		
		items.Add([| $(")") |])
		return [|
			override def ToString():
				return $expression
		|]
		
	def fieldsIncludingBaseType(type as TypeDefinition):
		return cat(fieldsOf(_baseType), fieldsOf(type))
		
	def fieldsOf(type as TypeDefinition):
		return type.Members.Select(NodeType.Field)
		
	def constructorForFields(fields as (Field)):
		ctor = [|
			def constructor():
				pass
		|]
		for f in fields:
			ctor.Parameters.Add(p=ParameterDeclaration(Name: f.Name, Type: f.Type))
			ctor.Body.Add([| self.$(f.Name) = $p |])
		return ctor
		
	def fieldsFrom(node as MethodInvocationExpression):
		return array(fieldFrom(expression) for expression in node.Arguments)
	
	def fieldFrom(node as Expression):
		match node:
			case [| $(ReferenceExpression(Name: name)) as $type |]:
				return fieldWith(name, type)
			case ReferenceExpression(Name: name):
				return fieldWith(name, TypeReference.Lift(_baseType))
				
	def fieldWith(name as string, type as TypeReference):
		if name.StartsWith("@"): // mutable field
			return [|
				public $(fieldName(name)) as $type
			|]
		return [|
			public final $name as $type
		|]
				
	def fieldName(name as string):
		return (name[1:] if name.StartsWith("@") else name)
		
	def registerType(type as TypeDefinition):
		_module.Members.Add(type)

def enclosingModule(node as Node) as Module:
	return node.GetAncestor(NodeType.Module)
