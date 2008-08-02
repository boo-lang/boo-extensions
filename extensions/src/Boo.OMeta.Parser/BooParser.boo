namespace Boo.OMeta.Parser

import Boo.OMeta
import Boo.PatternMatching

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

import System.Globalization

macro infix:
	
	l, op, r = infix.Arguments
	
	return ExpressionStatement([| $l = ((($l >> l, $op >> op, $r >> r) ^ newInfixExpression(op, l, r)) | $r) |])
	
macro infixr:
	
	l, op, r = infixr.Arguments
	
	return ExpressionStatement([| $l = ((($r >> l, $op >> op, $l >> r) ^ newInfixExpression(op, l, r)) | $r) |])
	
macro prefix:
	
	rule, op, next = prefix.Arguments
	
	return ExpressionStatement([| $rule = (($op >> op, $rule >> e) ^ newPrefixExpression(op, e)) | $next |])
	
macro list_of:
"""
Generates rules for lists of the given expression.

	list_of expression
	
Expands to something that matches:

	expression (COMMA expression)+
"""
	
	rule, = list_of.Arguments
	
	block as Block = list_of.ParentNode
	
	listRuleName = ReferenceExpression(Name: "${rule}_list")
	listRule = [| $listRuleName = ((($rule >> first), ++((COMMA, $rule >> e) ^ e) >> rest) ^ prepend(first, rest)) | ($rule >> v ^ [v]) |]
	block.Add(listRule)
	
	optionalRuleName = ReferenceExpression(Name: "optional_${rule}_list")
	optionalListRule = [| $optionalRuleName = $listRuleName | ("" ^ []) |]
	block.Add(optionalListRule)

ometa BooParser < WhitespaceSensitiveTokenizer:
	
	tokens:
		equality = "=="
		inequality = "!="
		assign = "="
		assign_inplace = "+=" | "-=" | "*=" | "/=" | "%=" | "^="
		xor = "^"
		plus = "+"
		minus = "-"
		exponentiation = "**"
		star = "*"
		division = "/"
		modulus = "%"
		bitwise_not = "~"
		bitwise_shift_left = "<<"
		bitwise_shift_right = ">>"
		bitwise_and = "&"
		bitwise_or = "|"
		hexnum = ("0x", ++(hex_digit | digit) >> ds) ^ makeString(ds)
		num = ++digit
		colon = ":"
		dot = "."
		comma = ","
		lparen = "(", enterWhitespaceAgnosticRegion
		rparen = ")", leaveWhitespaceAgnosticRegion
		lbrack = "[", enterWhitespaceAgnosticRegion
		rbrack = "]", leaveWhitespaceAgnosticRegion
		kw = (keywords >> value, ~(letter | digit)) ^ value
		tdqs = ('"""', ++(~'"""', _) >> s, '"""') ^ s
		sdqs = ('"', ++(~'"', _) >> s, '"') ^ s
		sqs = ("'", ++(~"'", _) >> s, "'") ^ s
		id = ((letter | '_') >> p, --(letter | digit | '_') >> s) ^ makeString(p, s)
		
	hex_digit = _ >> c as char and ((c >= char('a') and c <= char('f')) or (c >= char('A') and c <= char('Z'))) 
		
	keywords "class", "def", "import", "pass", "return", "true", \
		"false", "and", "or", "as", "not", "if", "is", "null", \
		"for", "in", "yield"
	
	keyword[expected] = ((KW >> t) and (expected is tokenValue(t))) ^ t
	
	module = (
		--EOL,
		(docstring >> s | ""),
		--import_declaration >> ids,
		--module_member >> members,
		--stmt >> stmts,
		--whitespace
	) ^ newModule(s, ids, members, stmts)
	
	docstring = (TDQS >> t, eol) ^ tokenValue(t)
	
	import_declaration = (IMPORT, qualified_name >> qn, eol) ^ newImport(qn)
	
	qualified_name = (ID >> qualifier, --((DOT, ID >> n) ^ n) >> suffix)^ buildQName(qualifier, suffix) 
	
	module_member = class_def | method
	
	class_def = (
		CLASS, ID >> className, begin_block, class_body >> body, end_block
	) ^ newClass(className, body)
	
	begin_block = COLON, INDENT
	
	end_block = DEDENT
	
	class_body = ((PASS, eol) ^ null) | (++class_member >> members ^ members)
	
	class_member = method | class_def
	
	method = (
		DEF, ID >> name, LPAREN, optional_parameter_list >> parameters, RPAREN, block >> body
	) ^ newMethod(name, parameters, body)
	
	list_of parameter
	
	parameter = ((ID >> name, AS, type_reference >> type) | (ID >> name)) ^ ParameterDeclaration(Name: tokenValue(name), Type: type)
	
	block = empty_block | non_empty_block
	
	empty_block = (begin_block, (PASS, eol), end_block) ^ Block()
	
	non_empty_block = (begin_block, ++stmt >> stmts, end_block)  ^ newBlock(stmts)
	
	stmt = ((stmt_block >> s) | (stmt_line >> s, eol)) ^ s
	
	stmt_line = (~~(ID, AS), stmt_declaration) \
		| stmt_expression \
		| stmt_return \
		| stmt_yield
		
	stmt_yield = (YIELD, assignment >> e, stmt_modifier >> m) ^ YieldStatement(Expression: e, Modifier: m)
	
	stmt_modifier = ((IF, assignment >> e) ^ StatementModifier(Type: StatementModifierType.If, Condition: e)) | ""
	
	stmt_declaration = (declaration >> d, ASSIGN, expression >> e) ^ newDeclarationStatement(d, e)
	
	declaration = (ID >> name, ((AS, type_reference >> typeRef) | "")) ^ newDeclaration(name, typeRef)
		
	stmt_block = stmt_if | stmt_for
	
	stmt_for = (FOR, declaration_list >> dl, IN, expression >> e, block >> body) ^ newForStatement(dl, e, body)
	
	stmt_if = (IF, expression >> e, block >> trueBlock) ^ newIfStatement(e, trueBlock)
	
	stmt_return = (RETURN, optional_expression >> e, stmt_modifier >> m) ^ ReturnStatement(Expression: e, Modifier: m)
	
	optional_expression = expression | ""

	stmt_expression = (multi_assignment | assignment) >> e ^ ExpressionStatement(Expression: e)
	
	multi_assignment = (expression >> l, ASSIGN >> op, assignment_list >> items) ^ newInfixExpression(op, l, newRValue(items))
	
	list_of assignment
	
	infixr assignment, (ASSIGN | ASSIGN_INPLACE), expression
	
	expression = or_expression
	
	infix or_expression, OR, and_expression
	
	infix and_expression, AND, not_expression
	
	not_expression = ((NOT >> op, expression >> e) ^ newPrefixExpression(op, e)) | membership_expression
	
	infix membership_expression, (IN | (NOT, IN)), identity_test_expression
	
	infix identity_test_expression, ((IS, NOT) | IS), comparison
	
	infix comparison, (EQUALITY | INEQUALITY | IS), bitwise_or_expression
	
	infix bitwise_or_expression, BITWISE_OR, bitwise_xor_expression
	
	infix bitwise_xor_expression, XOR, bitwise_and_expression
	
	infix bitwise_and_expression, BITWISE_AND, bitwise_shift_expression
	
	infix bitwise_shift_expression, bitwise_shift_op, term
	
	bitwise_shift_op = (BITWISE_SHIFT_LEFT | BITWISE_SHIFT_RIGHT)
	
	infix term, (PLUS | MINUS), factor
	
	infix factor, (STAR | DIVISION | MODULUS), signalled_expression
	
	prefix signalled_expression, MINUS, bitwise_not_expression
	
	prefix bitwise_not_expression, BITWISE_NOT, exponentiation_expression
	
	infix exponentiation_expression, EXPONENTIATION, try_cast
	
	try_cast = ((try_cast >> e, AS, type_reference >> typeRef) ^ TryCastExpression(Target: e, Type: typeRef)) | member_reference
	
	member_reference = ((expression >> e, DOT, ID >> name) ^ newMemberReference(e, name)) | slicing
	
	slicing = ((expression >> e, LBRACK, slice_list >> indices, RBRACK) ^ newSlicing(e, indices)) | invocation
	
	slice = (expression >> begin,
				((COLON, omitted_expression >> end,
					((COLON, omitted_expression >> step) | ""))
					| "")) ^ newSlice(begin, end, step)
				
	list_of slice
				
	omitted_expression = expression | ("" ^ OmittedExpression.Default)
		
	invocation = ((expression >> target, LPAREN, optional_expression_list >> args, RPAREN) ^ newInvocation(target, args)) \
		| atom
	
	type_reference = type_reference_simple
	
	type_reference_simple = (qualified_name >> qname) ^ SimpleTypeReference(Name: qname)
	
	atom = integer | boolean | reference | array_literal | list_literal \
		| string_literal | prefix | null_literal | parenthesized_expression
	
	parenthesized_expression = (LPAREN, expression >> e, RPAREN) ^ e
		
	null_literal = NULL ^ [| null |]
	
	prefix = ((BITWISE_NOT | MINUS) >> op, expression >> e) ^ newPrefixExpression(op, e)
	
	string_literal = ((SDQS | TDQS | SQS) >> s) ^ newStringLiteral(s)
	
	array_literal = (LPAREN, (COMMA ^ (items=[])) | (expression_list >> items, (COMMA | "")), RPAREN) ^ newArrayLiteral(items)
	
	list_literal = (LBRACK, optional_expression_list >> items, RBRACK) ^ newListLiteral(items)
	
	list_of expression
	
	list_of declaration
		
	reference = ID >> r ^ newReference(r) 
	
	integer = (NUM >> n ^ newInteger(n, NumberStyles.None)) \
		| (HEXNUM >> n ^ newInteger(n, NumberStyles.HexNumber))
	
	boolean = true_literal | false_literal
	
	true_literal = TRUE ^ [| true |]
	
	false_literal = FALSE ^ [| false |]
	
	eol = ++EOL | ~_	
	
	def newSlicing(target as Expression, slices):
		node = SlicingExpression(Target: target)
		for slice in slices: node.Indices.Add(slice)
		return node
		
	def newSlice(begin as Expression, end as Expression, step as Expression):
		return Slice(begin, end, step)
	
	def newRValue(items as List):
		if len(items) > 1: return newArrayLiteral(items)
		return items[0]
	
	def newForStatement(declarations, e as Expression, body as Block):
		node = ForStatement(Iterator: e, Block: body)
		for d in declarations: node.Declarations.Add(d)
		return node
	
	def newDeclaration(name, type as TypeReference):
		return Declaration(Name: tokenValue(name), Type: type)
	
	def newDeclarationStatement(d as Declaration,  initializer as Expression):
		return DeclarationStatement(Declaration: d, Initializer: initializer)
	
	def newIfStatement(condition as Expression, trueBlock as Block):
		return IfStatement(Condition: condition, TrueBlock: trueBlock)
		
	def newModule(doc, imports, members, stmts):
		m = Module(Documentation: doc)
		for item in imports: m.Imports.Add(item)
		for member in members: m.Members.Add(member)
		for stmt as Statement in stmts: m.Globals.Add(stmt)
		return m
		
	def newImport(qname as string):
		return Import(Namespace: qname)
	
	def newInteger(t, style as NumberStyles):
		value = int.Parse(tokenValue(t), style)
		return IntegerLiteralExpression(Value: value)
		
	def newMethod(name, parameters, body as Block):
		node = Method(Name: tokenValue(name), Body: body)
		for p in parameters: node.Parameters.Add(p)
		return node
		
	def newClass(name, members):
		klass = ClassDefinition(Name: tokenValue(name))
		if members is not null: 
			for member in members: klass.Members.Add(member)
		return klass
		
	def newInvocation(target as Expression, args as List):
		mie = MethodInvocationExpression(Target: target)
		for arg in args: mie.Arguments.Add(arg)
		return mie
		
	def newReference(t):
		return ReferenceExpression(Name: tokenValue(t))
		
	def newMemberReference(target as Expression, name):
		return MemberReferenceExpression(Target: target, Name: tokenValue(name))
		
	def newArrayLiteral(items):
		literal = ArrayLiteralExpression()
		for item in items:
			literal.Items.Add(item)
		return literal
		
	def newListLiteral(items):
		literal = ListLiteralExpression()
		for item in items: literal.Items.Add(item)
		return literal
		
	def newStringLiteral(s):
		return StringLiteralExpression(Value: tokenValue(s))
		
	def newInfixExpression(op, l as Expression, r as Expression):
		return BinaryExpression(Operator: binaryOperatorFor(op), Left: l, Right: r)
		
	def newPrefixExpression(op, e as Expression):
		return UnaryExpression(Operator: unaryOperatorFor(op), Operand: e)
		
	def unaryOperatorFor(op):
		match tokenValue(op):
			case "not": return UnaryOperatorType.LogicalNot
			case "-": return UnaryOperatorType.UnaryNegation
			case "~": return UnaryOperatorType.OnesComplement
		
	def binaryOperatorFor(op):
		match tokenValue(op):
			case "is": return BinaryOperatorType.ReferenceEquality
			case "and": return BinaryOperatorType.And
			case "or": return BinaryOperatorType.Or
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
		
	def newAssignment(l as Expression, r as Expression):
		return [| $l = $r |]
		
	def newBlock(stmts):
		b = Block()
		for item in stmts:
			b.Statements.Add(item)
		return b
		
	def prepend(first, tail as List):
		if first is null: return tail
		return [first] + tail
		
	def buildQName(q, rest):
		return join(tokenValue(t) for t in prepend(q, rest), '.')

