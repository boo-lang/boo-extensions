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

	data Expression = Const(Value as int) | Add(Left, Right) // omitted types assumed to be Expression
	
	
	data SingleValue(Value as int)
	
	
	data TypeWithMutableField(@MutableValue as int) // @ makes the field mutable
"""
	
	DataMacroExpansion(data)

class DataMacroExpansion:
	
	_module as TypeDefinition
	_superType as TypeDefinition
	_superTypeRef as TypeReference
	
	def constructor(node as MacroStatement):
		
		assert 1 == len(node.Arguments)
		_module = enclosingModule(node)
		
		match node.Arguments[0]:
			case [| $left = $right |]:
				assert node.Body.IsEmpty
				_superType = createBaseType(left)
				expandDataConstructors(right)
				
			case [| $(ctor=MethodInvocationExpression()) < $superType |]:
				_superTypeRef = TypeReference.Lift(superType)
				_superType = ClassDefinition()
				expandDataConstructorWithBody(ctor, node.Body)
				
			case ctor=MethodInvocationExpression():
				_superType = [|
					class object:
						pass
				|]
				expandDataConstructorWithBody(ctor, node.Body)
				
	def expandDataConstructorWithBody(ctor as Expression, body as Block):
		expandDataConstructor(ctor).Members.Extend(TypeMember.Lift(body))
		
	def createBaseType(node as Expression):
		type = superTypeForExpression(node)
		type.LexicalInfo = node.LexicalInfo
		registerType(type)
		return type
		
	def abstractType(name as string):
		type = [|
			partial abstract class $name:
				pass
		|]
		return type
		
	def superTypeForExpression(node as Expression):
		match node:
			case ReferenceExpression(Name: name):
				return abstractType(name)
				
			case [| $(ReferenceExpression(Name: name)) < $(ReferenceExpression(Name: superType)) |]:
				type = [|
					partial abstract class $name($superType):
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
		addSuperInvocationTo ctor
		
		type.Members.Add(ctor)
		for ctor in constructorsWithDefaultValues(fields):
			type.Members.Add(ctor)
		
		registerType(type)
		return type
		
	def addSuperInvocationTo(ctor as Constructor):
		superInvocation = [| super() |]
		i = 0
		for field as Field in fieldsOf(_superType):
			ctor.Parameters.Insert(i++, 
				ParameterDeclaration(Name: field.Name, Type: field.Type))
			superInvocation.Arguments.Add(ReferenceExpression(field.Name))
		ctor.Body.Insert(0, superInvocation)
		
	def dataConstructorTypeForExpression(node as Expression):
		match node:
			case ReferenceExpression(Name: name):
				type = [|
					partial class $name($(superTypeRef())):
						pass
				|]
				for arg in _superType.GenericParameters:
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
		for field in fieldsIncludingBaseType(type):
			if comma: items.Add([| ", " |])
			items.Add(toStringForField(field))
			
			comma = true
		
		items.Add([| $(")") |])
		return [|
			override def ToString():
				return $expression
		|]
		
	def toStringForField(field as Field):
		return [| Boo.Adt.adtFieldToString(self.$(field.Name)) |]
		
	def fieldsIncludingBaseType(type as TypeDefinition):
		return cat(fieldsOf(_superType), fieldsOf(type))
		
	def fieldsOf(type as TypeDefinition):
		return type.Members.Select(NodeType.Field)
		
	def constructorForFields(fields as (Field)):
		ctor = constructorDeclarationFor(fields)
		for p in ctor.Parameters:
			ctor.Body.Add([| self.$(p.Name) = $p |])
		return ctor
		
	def constructorDeclarationFor(fields as (Field)):
		ctor = [|
			def constructor():
				pass
		|]
		for f in fields:
			ctor.Parameters.Add(ParameterDeclaration(Name: f.Name, Type: f.Type))
		ctor.Parameters.HasParamArray = len(fields) > 0 and fields[-1].ContainsAnnotation("*")
		return ctor
		
	def constructorsWithDefaultValues(fields as (Field)):
		
		for i in range(len(fields)-1, -1):
			if defaultValueOf(fields[i]) is null:
				break
				
			requiredFields = fields[:i]
			optionalFields = fields[i:]
			
			ctor = constructorDeclarationFor(requiredFields)
			baseCtorInvocation = [| self() |]
			for p in ctor.Parameters:
				baseCtorInvocation.Arguments.Add([| $p |])
			for f in optionalFields:
				baseCtorInvocation.Arguments.Add(defaultValueOf(f))
			ctor.Body.Add(baseCtorInvocation)
			yield ctor
			
	def defaultValueOf(f as Field) as Expression:
		return f["DefaultValue"]

	def fieldsFrom(node as MethodInvocationExpression):
		return array(fieldFrom(expression) for expression in node.Arguments)
	
	def fieldFrom(node as Expression) as Field:
		match node:
			case [| *$(ReferenceExpression(Name: name)) as $(arrayType = ArrayTypeReference()) |]:
				return arrayField(name, arrayType)
			case [| *$(ReferenceExpression(Name: name)) |]:
				return arrayField(name, ArrayTypeReference(superTypeRef()))
			case [| $(ReferenceExpression(Name: name)) as $type |]:
				return fieldWith(name, type)
			case [| $declaration = $defaultValue |]:
				f = fieldFrom(declaration)
				f.Annotate("DefaultValue", defaultValue)
				return f
			case ReferenceExpression(Name: name):
				return fieldWith(name, superTypeRef())
				
	def arrayField(name as string, arrayType as ArrayTypeReference):
		field = fieldWith(name, arrayType)
		field.Annotate("*")
		return field
		
	def superTypeRef():
		if _superTypeRef is not null:
			return _superTypeRef
		return TypeReference.Lift(_superType)
				
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
	
def adtFieldToString(v):
	if v is null: return "null"
	if v isa System.Array: return "[$(join(v, ', '))]"
	return v.ToString()
