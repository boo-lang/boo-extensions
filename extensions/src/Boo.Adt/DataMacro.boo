namespace Boo.Adt

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.PatternMatching

class DataMacro(AbstractAstMacro):
	
	override def Expand(node as MacroStatement):
		DataMacroExpansion(node)

class DataMacroExpansion:
	
	_module as Module
	_baseType as TypeReference
	
	def constructor(node as MacroStatement):
		
		assert 1 == len(node.Arguments)
		
		match node.Arguments[0]:
			case BinaryExpression(
					Operator: BinaryOperatorType.Assign,
					Left: left,
					Right: right):
				_module = enclosingModule(node)
				_baseType = createBaseType(left)
				expandDataConstructors(right)
		
	def createBaseType(node as Expression):
		type = baseTypeForExpression(node)
		registerType(type)
		
		typeRef = TypeReference.Lift(type)
		typeRef.LexicalInfo = node.LexicalInfo
		return typeRef
		
	def baseTypeForExpression(node as Expression):
		match node:
			case re=ReferenceExpression():
				type = [|
					abstract class $re:
						pass
				|]
				return type
				
			case mie=MethodInvocationExpression(
						Target: ReferenceExpression(Name: name),
						Arguments: (ReferenceExpression(Name: baseType),)):
				type = [|
					abstract class $name($baseType):
						pass
				|]
				return type
				
			case gre=SlicingExpression(
						Target: ReferenceExpression(Name: name)):
				type = [|
					abstract class $name[of T]:
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
			case BinaryExpression(Operator: BinaryOperatorType.BitwiseOr,
								Left: left,
								Right: right):
				expandDataConstructors(left)
				expandDataConstructors(right)
			case MethodInvocationExpression():
				expandDataConstructor(node)
				
	def expandDataConstructor(node as MethodInvocationExpression):
		type = dataConstructorTypeForExpression(node.Target)
		type.LexicalInfo = node.LexicalInfo
		for arg in node.Arguments:
			type.Members.Add(fieldForArg(arg))	
		type.Members.Add(toStringForType(type))
		type.Members.Add(equalsForType(type))
		type.Members.Add(constructorForInvocation(node))	
		registerType(type)
		
	def dataConstructorTypeForExpression(node as Expression):
		match node:
			case ReferenceExpression(Name: name):
				type = [|
					class $name($_baseType):
						pass
				|]
				genericBaseType = _baseType as GenericTypeReference
				if genericBaseType is null: return type
				
				for arg in genericBaseType.GenericArguments:
					match arg:
						case SimpleTypeReference(Name: name):
							type.GenericParameters.Add(
								GenericParameterDeclaration(Name: name))
				return type
						
		
	def equalsForType(type as TypeDefinition):
			
		method = [|
			override def Equals(o):
				if o is null: return false
				// (self as object) to workaround a generic type emission bug
				if (self as object).GetType() != o.GetType(): return false
				other as $type = o
		|]
	
		for field in fields(type):
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
		for field in fields(type):
			if comma: items.Add([| ", " |])
			items.Add([| self.$(field.Name) |])
			comma = true
		
		items.Add([| $(")") |])
		return [|
			override def ToString():
				return $expression
		|]
		
	def fields(type as TypeDefinition):
		return f for f as Field in type.Members.Select(NodeType.Field)
		
	def constructorForInvocation(node as MethodInvocationExpression):
		ctor = [|
			def constructor():
				pass
		|]
		for arg in node.Arguments:
			match arg:
				case TryCastExpression(
						Target: ReferenceExpression(Name: name),
						Type: type):
					ctor.Parameters.Add(
						ParameterDeclaration(Name: name, Type: type))
					ctor.Body.Add([|
						self.$name = $(ReferenceExpression(name))
					|])
		return ctor
	
	def fieldForArg(node as TryCastExpression):
		match node.Target:
			case ReferenceExpression(Name: name):
				return [|
					public final $name as $(node.Type)
				|]
		
	def registerType(type as TypeDefinition):
		_module.Members.Add(type)

def enclosingModule(node as Node) as Module:
	return node.GetAncestor(NodeType.Module)
