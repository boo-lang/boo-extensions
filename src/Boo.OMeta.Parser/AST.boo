namespace Boo.OMeta.Parser

import System.Globalization
import Boo.OMeta
import Boo.Lang.PatternMatching
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

def newMacro(name, args, body, m):
	node = MacroStatement(Name: tokenValue(name), Body: body, Modifier: m)
	for arg in args: node.Arguments.Add(arg)
	return node

def newSlicing(target as Expression, slices):
	node = SlicingExpression(Target: target)
	for slice in slices: node.Indices.Add(slice)
	return node
	
def newSlice(begin as Expression, end as Expression, step as Expression):
	return Slice(begin, end, step)

def newRValue(items as List):
	if len(items) > 1: return newArrayLiteral(items)
	return items[0]

def newForStatement(declarations, e as Expression, body as Block, orBlock as Block, thenBlock as Block):
	node = ForStatement(Iterator: e, Block: body, OrBlock: orBlock, ThenBlock: thenBlock)
	for d in declarations: node.Declarations.Add(d)
	return node

def newDeclaration(name, type as TypeReference):
	return Declaration(Name: tokenValue(name), Type: type)

def newDeclarationStatement(d as Declaration,  initializer as Expression):
	return DeclarationStatement(Declaration: d, Initializer: initializer)
	
def newUnpackStatement(declarations, e as Expression, m as StatementModifier):
	stmt = UnpackStatement(Expression: e, Modifier: m)
	for d in declarations: stmt.Declarations.Add(d)
	return stmt

def newIfStatement(condition as Expression, trueBlock as Block, falseBlock as Block):
	return IfStatement(Condition: condition, TrueBlock: trueBlock, FalseBlock: falseBlock)
	
def newCallable(modifiers, name, genericParameters as List, parameters as List, type):
	node = CallableDefinition(Name: tokenValue(name), ReturnType: type)
	
	#return setUpType(ClassDefinition(Name: tokenValue(name)), attributes, modifiers, genericParameters, baseTypes, members)	
	setUpMember(node, null, modifiers)
	
	if genericParameters is not null:
		for genericParameter in genericParameters:			
			node.GenericParameters.Add(genericParameter)
	
	if parameters[1] is not null: //Check if ParamArray is present
		setUpParameters node, parameters
		node.Parameters.HasParamArray = true
	else:
		setUpParameters node, parameters[0]
	return node
	
def newModule(doc, imports, members, stmts):
	m = Module(Documentation: doc)
	for item in imports: m.Imports.Add(item)
	for member in flatten(members):
		if member isa Attribute:
			m.AssemblyAttributes.Add(member)
		else:
			m.Members.Add(member)
	for stmt as Statement in stmts: m.Globals.Add(stmt)
	return m
	
def newImport(qname as string, assembly, alias):
	assemblyReference = null
	if assembly isa Token:
		assemblyReference = ReferenceExpression(Name: tokenValue(assembly))
	else:
		assemblyReference = ReferenceExpression(Name: assembly) if assembly is not null
		
	importAlias = null
	if alias isa Token:
		importAlias =	ReferenceExpression(Name: tokenValue(alias))
	else:
		importAlias =	ReferenceExpression(Name: alias) if alias is not null
		
	return Import(Namespace: qname, AssemblyReference: assemblyReference, Alias: importAlias)

def newInteger(t, style as NumberStyles):
	value = int.Parse(tokenValue(t), style)
	return IntegerLiteralExpression(Value: value)

def newFloat(t):
	value = double.Parse(t)
	return DoubleLiteralExpression(Value: value)

def newEvent(attributes, modifiers, name, type):
	return setUpMember(Event(Name: tokenValue(name), Type: type), attributes, modifiers)
	
def newField(attributes, modifiers, name, type, initializer):
	return setUpMember(Field(Name: tokenValue(name), Type: type, Initializer: initializer), attributes, modifiers)
	
def newProperty(attributes, modifiers, name, parameters, type, getter, setter):
	node = Property(Name: tokenValue(name), Type: type, Getter: getter, Setter: setter)
	setUpParameters node, parameters
	return setUpMember(node, attributes, modifiers)
	
def setUpAttributes(node as INodeWithAttributes, attributes) as Node:
	for a in flatten(attributes):
		node.Attributes.Add(a)
	return node
	
def setUpMember(member as TypeMember, attributes, modifiers):
	setUpAttributes member, attributes
	for m as TypeMemberModifiers in flatten(modifiers): member.Modifiers |= m
	return member
	
def setUpParameters(node as INodeWithParameters, parameters):
	for p in flatten(parameters): node.Parameters.Add(p)
	
def newMethod(attributes, modifiers, name, parameters as List, returnTypeAttributes, returnType as TypeReference, body as Block) as Method:
	node = Method(Name: tokenValue(name), Body: body, ReturnType: returnType)

	if parameters[1] != null: //Check if ParamArray is present
		setUpParameters node, parameters
		node.Parameters.HasParamArray = true
	else:
		setUpParameters node, parameters[0]

	for a in flatten(returnTypeAttributes): node.ReturnTypeAttributes.Add(a)
	return setUpMember(node, attributes, modifiers)
	
def newGenericMethod(attributes, modifiers, name, genericParameters, parameters as List, returnTypeAttributes, returnType as TypeReference, body as Block):
	node = newMethod(attributes, modifiers, name, parameters, returnTypeAttributes, returnType, body)
	for gp in flatten(genericParameters): node.GenericParameters.Add(gp)
	return node
	
	
def newConstructor(attributes, modifiers, genericParameters, parameters as List, body as Block):
	node = Constructor(Name: "constructor", Body: body)

	if parameters[1] != null: //Check if ParamArray is present
		setUpParameters node, parameters
		node.Parameters.HasParamArray = true
	else:
		setUpParameters node, parameters[0]

	setUpMember(node, attributes, modifiers)
	
	for gp in flatten(genericParameters): node.GenericParameters.Add(gp)
	return node	
	
	

def newGenericTypeReference(qname, args):
	node = GenericTypeReference(Name: qname)
	for arg in flatten(args): node.GenericArguments.Add(arg)
	return node

def newGenericTypeDefinitionReference(qname, placeholders as List):
	return GenericTypeDefinitionReference(Name: qname,  GenericPlaceholders: placeholders.Count)


def newGenericParameterDeclaration(name, constraints):
	node = GenericParameterDeclaration(Name: tokenValue(name))

	if constraints is not null:
		for constraint in constraints:
			if constraint isa TypeReference:
				node.BaseTypes.Add(constraint)
			else:
				node.Constraints |= cast(GenericParameterConstraints, constraint)
	
	return node
	
def newParameterDeclaration(attributes, name, type):
	node = ParameterDeclaration(Name: tokenValue(name), Type: type)
	return setUpAttributes(node, attributes)
	
def newEnum(attributes, modifiers, name, members):
	return setUpType(EnumDefinition(Name: tokenValue(name)), attributes, modifiers, null, null, members)
	
def newCallableTypeReference(params, type):
	node = CallableTypeReference(ReturnType: type)
	i = 0
	for p in flatten(params):
		node.Parameters.Add(ParameterDeclaration(Name: "arg${i++}", Type: p))
	return node
	
def newStatementModifier(t, e as Expression):
	return StatementModifier(Type: t, Condition: e)
	
def newGeneratorExpressionBody(dl, e, f):
	node = GeneratorExpression(Iterator: e, Filter: f)
	for d in flatten(dl): node.Declarations.Add(d)
	return node
	
def newGeneratorExpression(projection, body as List):
	node as GeneratorExpression = body[0]
	node.Expression = projection
	if len(body) == 1: return node
	
	e = ExtendedGeneratorExpression()
	for item in body: e.Items.Add(item)
	return e
	
def newEnumField(attributes, name, initializer):
	match initializer:
		case [| -$(e=IntegerLiteralExpression()) |]:
			e.Value *= -1
			initializer = e
		otherwise:
			pass
	return setUpMember(EnumMember(Name: tokenValue(name), Initializer: initializer), attributes, null)
	
def newClass(attributes, modifiers, name, genericParameters, baseTypes, members):
	return setUpType(ClassDefinition(Name: tokenValue(name)), attributes, modifiers, genericParameters, baseTypes, members)
	
def setUpType(type as TypeDefinition, attributes, modifiers, genericParameters, baseTypes, members):
	if members is not null: 
		for member in members: type.Members.Add(member)
	if baseTypes is not null:
		for baseType in baseTypes: type.BaseTypes.Add(baseType)
	if genericParameters is not null:
		for genericParameter in genericParameters: type.GenericParameters.Add(genericParameter)
			
	return setUpMember(type, attributes, modifiers)
	
macro setUpArgs:
	node, args = setUpArgs.Arguments
	code = [|
		if $args is not null:
			for arg in $args:
				if arg isa ExpressionPair:
					$node.NamedArguments.Add(arg)
				else:
					$node.Arguments.Add(arg)
	|]
	return code
	
def newAttribute(name, args):
	node = Attribute(Name: tokenValue(name))
	setUpArgs node, args
	return node
	
def newNamedArgument(name, value):
	return ExpressionPair(First: newReference(name), Second: value)
	
def newInterface(attributes, modifiers, name, baseTypes, members):
	return setUpType(InterfaceDefinition(Name: tokenValue(name)), attributes, modifiers, null, baseTypes, members)
	
def newInvocation(target as Expression, args as List, genericArgs as object):
	if genericArgs is not null:
		target = GenericReferenceExpression(Target: target)
		for arg in genericArgs:
			(target as GenericReferenceExpression).GenericArguments.Add(arg)
	
	mie = MethodInvocationExpression(Target: target)
	setUpArgs mie, args	
	return mie
	
def newQuasiquoteBlock(m):
	return QuasiquoteExpression(Node: m)
	
def newQuasiquoteExpression(s):
	return QuasiquoteExpression(Node: s)
	
def newReference(t):
	return ReferenceExpression(Name: tokenValue(t))
	
def newMemberReference(target as Expression, name):
	return MemberReferenceExpression(Target: target, Name: tokenValue(name))
	
def newArrayLiteral(type, items):
	node = newArrayLiteral(items)
	node.Type = type
	return node
	
def newArrayLiteral(items):
	literal = ArrayLiteralExpression()
	for item in items:
		literal.Items.Add(item)
	return literal
	
def newListLiteral(items):
	literal = ListLiteralExpression()
	for item in items: literal.Items.Add(item)
	return literal
	
def newHashLiteral(items):
	literal = HashLiteralExpression()
	for item in items: literal.Items.Add(item)
	return literal
	
def newStringLiteral(s):
	return StringLiteralExpression(Value: tokenValue(s))
	
def newStringInterpolation(items as List):
	if len(items) == 0: return StringLiteralExpression("")
	if len(items) == 1 and items[0] isa StringLiteralExpression:
		return items[0]
	node = ExpressionInterpolationExpression()
	for item in items: node.Expressions.Add(item)
	return node
	
def newConditionalExpression(condition, trueValue, falseValue):
	return ConditionalExpression(Condition: condition, TrueValue: trueValue, FalseValue: falseValue)
	
def newBlockExpression(parameters as List, body):
	node = BlockExpression(Body: body)
	for p in parameters[0]:
		node.Parameters.Add(p)
	return node
	
def newTypeofExpression(type):
	return TypeofExpression(Type: type)
	
def newInvocationWithBlock(invocation as MethodInvocationExpression, block as BlockExpression):
	node = invocation.CloneNode()
	node.Arguments.Add(block)
	return node
	
def newInfixExpression(op, l as Expression, r as Expression):
	return BinaryExpression(Operator: binaryOperatorFor(op), Left: l, Right: r)
	
def newPrefixExpression(op, e as Expression):
	return UnaryExpression(Operator: unaryOperatorFor(op), Operand: e)
	
def unaryOperatorFor(op):
	match tokenValue(op):
		case "not": return UnaryOperatorType.LogicalNot
		case "-": return UnaryOperatorType.UnaryNegation
		case "~": return UnaryOperatorType.OnesComplement
		case "++": return UnaryOperatorType.Increment
		case "--": return UnaryOperatorType.Decrement
		case "*": return UnaryOperatorType.Explode
	
def binaryOperatorFor(op):
	match tokenValue(op):
		case "is": return BinaryOperatorType.ReferenceEquality
		case "is not": return BinaryOperatorType.ReferenceInequality
		case "in": return BinaryOperatorType.Member
		case "not in": return BinaryOperatorType.NotMember
		case "and": return BinaryOperatorType.And
		case "or": return BinaryOperatorType.Or
		case "|": return BinaryOperatorType.BitwiseOr
		case "&": return BinaryOperatorType.BitwiseAnd
		case "^": return BinaryOperatorType.ExclusiveOr
		case "+": return BinaryOperatorType.Addition
		case "-": return BinaryOperatorType.Subtraction
		case "*": return BinaryOperatorType.Multiply
		case "**": return BinaryOperatorType.Exponentiation
		case "/": return BinaryOperatorType.Division
		case "%": return BinaryOperatorType.Modulus
		case "=": return BinaryOperatorType.Assign
		case "==": return BinaryOperatorType.Equality
		case "!=": return BinaryOperatorType.Inequality
		case "+=": return BinaryOperatorType.InPlaceAddition
		case "-=": return BinaryOperatorType.InPlaceSubtraction
		case "/=": return BinaryOperatorType.InPlaceDivision
		case "*=": return BinaryOperatorType.InPlaceMultiply
		case "^=": return BinaryOperatorType.InPlaceExclusiveOr
		case "&=": return BinaryOperatorType.InPlaceBitwiseAnd
		case "|=": return BinaryOperatorType.InPlaceBitwiseOr
		case ">>": return BinaryOperatorType.ShiftRight
		case "<<": return BinaryOperatorType.ShiftLeft
		case "<": return BinaryOperatorType.LessThan
		case "<=": return BinaryOperatorType.LessThanOrEqual
		case ">": return BinaryOperatorType.GreaterThan
		case ">=": return BinaryOperatorType.GreaterThanOrEqual
		case ">>=": return BinaryOperatorType.InPlaceShiftRight
		case "<<=": return BinaryOperatorType.InPlaceShiftLeft
	
def newAssignment(l as Expression, r as Expression):
	return [| $l = $r |]
	
def newBlock(contents):
	b = Block()
	match contents:
		case Statement():
			b.Statements.Add(contents)
		otherwise:
			for item in contents:
				b.Statements.Add(item)
	return b
	
def prepend(first, tail as List):
	if first is null: return tail
	return [first] + tail
	
def buildQName(q, rest):
	return join(tokenValue(t) for t in prepend(q, rest), '.')

def newGenericParameterConstraint(constraint):
	match tokenValue(constraint):
		case "class": return GenericParameterConstraints.ReferenceType
		case "struct": return GenericParameterConstraints.ValueType
		case "constructor": return GenericParameterConstraints.Constructable
		
def newGotoStatement(label, modifier):
	return GotoStatement(Label: ReferenceExpression(Name: tokenValue(label)), Modifier: modifier)