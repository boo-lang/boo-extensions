namespace Boo.OMeta.Parser

import Boo.OMeta
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
	
	return ExpressionStatement([| $rule = ($op >> op, $rule >> e) ^ newPrefixExpression(op, e) | $next |])
	
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
		qq_begin = "[|"
		qq_end = "|]"
		equality = "=="
		inequality = "!="
		assign = "="
		assign_inplace = "+=" | "-=" | "*=" | "/=" | "%=" | "^=" | "&=" | "|="
		xor = "^"
		increment = "++"
		decrement = "--"
		plus = "+"
		minus = "-"
		exponentiation = "**"
		star = "*"
		division = "/"
		modulus = "%"
		ones_complement = "~"
		bitwise_shift_left = "<<"
		bitwise_shift_right = ">>"
		greater_than_eq = ">="
		greater_than = ">"
		less_than_eq = "<="
		less_than = "<"
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
		lbrace = "{", enterWhitespaceAgnosticRegion
		rbrace = "}", leaveWhitespaceAgnosticRegion
		
		kw = (keywords >> value, ~(letter | digit | '_')) ^ value
		tdq = '"""'
		dq = '"'
		sqs = ("'", ++(~"'", _) >> s, "'") ^ s
		id = ((letter | '_') >> p, --(letter | digit | '_') >> s) ^ makeString(p, s)
		
	space = line_comment | super
	
	line_comment = '#', --(~newline, _)
		
	hex_digit = _ >> c as char and ((c >= char('a') and c <= char('f')) or (c >= char('A') and c <= char('Z'))) 
		
	keywords "class", "def", "import", "pass", "return", "true", \
		"false", "and", "or", "as", "not", "if", "is", "null", \
		"for", "interface", "in", "yield", "self", "super", "of", \
		"event", "private", "protected", "internal", "public", "enum", \
		"callable"
	
	keyword[expected] = ((KW >> t) and (expected is tokenValue(t))) ^ t
	
	module = (
		--EOL,
		(docstring >> s | ""),
		--import_declaration >> ids,
		--module_member >> members,
		--stmt >> stmts,
		--whitespace
	) ^ newModule(s, ids, members, stmts)
	
	docstring = (TDQ, ++(~tdq, string_char) >> s, TDQ, eol) ^ makeString(s)
	
	import_declaration = (IMPORT, qualified_name >> qn, eol) ^ newImport(qn)
	
	qualified_name = (ID >> qualifier, --((DOT, ID >> n) ^ n) >> suffix)^ buildQName(qualifier, suffix) 
	
	module_member = assembly_attribute | type_def | method
	
	type_def = class_def | interface_def | enum_def | callable_def
	
	callable_def = (CALLABLE, ID >> name, method_parameters >> parameters, optional_type >> type, eol) ^ newCallable(name, parameters, type)
	
	class_def = (
		attributes >> attrs,
		member_modifiers >> mod,
		CLASS, ID >> className, super_types >> superTypes, begin_block, class_body >> body, end_block
	) ^ newClass(attrs, mod, className, superTypes, body)
	
	interface_def = (
		attributes >> attrs,
		member_modifiers >> mod,
		INTERFACE, ID >> name, super_types >> superTypes, begin_block, interface_body >> body, end_block
	) ^ newInterface(attrs, mod, name, superTypes, body)
	
	enum_def = (
		attributes >> attrs, 
		member_modifiers >> mod,
		ENUM, ID >> name, begin_block, enum_body >> body, end_block
	) ^ newEnum(attrs, mod, name, body)
	
	enum_body = ++enum_field >> fields ^ fields
	
	enum_field = (attributes >> attrs, ID >> name, ((ASSIGN, expression >> e) | ""), eol) ^ newEnumField(attrs, name, e)
	
	super_types = ((LPAREN, optional_type_reference_list >> types, RPAREN) ^ types) | ""
	
	begin_block = COLON, INDENT
	
	end_block = DEDENT
	
	class_body = no_member | (++class_member >> members ^ members)
	
	interface_body = no_member
	
	no_member = (PASS, eol) ^ null
	
	class_member = type_def | method | property_def | field | event_def
	
	event_def = (
		attributes >> attrs,
		member_modifiers >> mod,
		EVENT, ID >> name, optional_type >> type, eol
	) ^ newEvent(attrs, mod, name, type)
	
	property_def = (
		attributes >> attrs,
		member_modifiers >> mod,
		ID >> name, property_parameters >> parameters, optional_type >> type,
		begin_block,
		(
			(property_getter >> pg, property_setter >> ps)
			| (property_setter >> ps, property_getter >> pg)
			| (property_setter >> ps)
			| (property_getter >> pg)
		),
		end_block
	) ^ newProperty(attrs, mod, name, parameters, type, pg, ps)
	
	property_parameters = ((LBRACK, parameter_list >> parameters, RBRACK) | "") ^ parameters
	
	property_getter = accessor["get"]
	
	property_setter = accessor["set"]
	
	accessor[key] = (
		attributes >> attrs,
		member_modifiers >> mod, 
		(ID >> name and (tokenValue(name) == key)),
		block >> body
	) ^ newMethod(attrs, mod, name, null, null, null, body)
	
	field = (
		attributes >> attrs,
		member_modifiers >> mod,
		ID >> name, optional_type >> type, field_initializer >> initializer, eol
	) ^ newField(attrs, mod, name, type, initializer)
	
	field_initializer = (ASSIGN, rvalue) | ""
	
	member_modifiers = --((PRIVATE ^ TypeMemberModifiers.Private) | (PUBLIC ^ TypeMemberModifiers.Public)) >> all ^ all
	
	method = (
		attributes >> attrs,
		member_modifiers >> mod, DEF, ID >> name, method_parameters >> parameters,
			attributes >> returnTypeAttributes, optional_type >> type,
			block >> body
	) ^ newMethod(attrs, mod, name, parameters, returnTypeAttributes, type, body)
	
	method_parameters = (LPAREN, optional_parameter_list >> parameters, RPAREN) ^ parameters
	
	list_of parameter
	
	assembly_attribute = (
		LBRACK, (ID >> name and (tokenValue(name) == "assembly")), COLON,
		attribute_list >> value, 
		RBRACK, eol) ^ value
	
	attributes = --((LBRACK, attribute_list >> value, RBRACK, --EOL) ^ value) >> all ^ all
	
	attribute = (ID >> name, attribute_arguments >> args) ^ newAttribute(name, args)
	
	attribute_arguments = invocation_arguments | ""
	
	list_of attribute
	
	parameter = (attributes >> attrs, ID >> name, optional_type >> type) ^ newParameterDeclaration(attrs, name, type)
	
	optional_type = (AS, type_reference) | ""
	
	block = empty_block | non_empty_block
	
	empty_block = (begin_block, (PASS, eol), end_block) ^ Block()
	
	non_empty_block = (begin_block, ++stmt >> stmts, end_block)  ^ newBlock(stmts)
	
	stmt = stmt_block | stmt_line
	
	stmt_line = (~~(ID, AS), stmt_declaration) \
		| stmt_expression \
		| stmt_macro \
		| stmt_return \
		| stmt_yield
		
	stmt_macro = (ID >> name, assignment_list >> args, ((block >> b) | (stmt_modifier >> m))) ^ newMacro(name, args, b, m)
		
	stmt_yield = (YIELD, assignment >> e, stmt_modifier >> m) ^ YieldStatement(Expression: e, Modifier: m)
	
	stmt_modifier = ((stmt_modifier_node >> value, eol) ^ value) | (eol ^ null)
	
	stmt_modifier_node = (IF, assignment >> e) ^ StatementModifier(Type: StatementModifierType.If, Condition: e)
	
	stmt_declaration = (declaration >> d, ((ASSIGN, expression >> e) | ""), eol) ^ newDeclarationStatement(d, e)
	
	declaration = (ID >> name, ((AS, type_reference >> typeRef) | "")) ^ newDeclaration(name, typeRef)
		
	stmt_block = stmt_if | stmt_for
	
	stmt_for = (FOR, declaration_list >> dl, IN, rvalue >> e, block >> body) ^ newForStatement(dl, e, body)
	
	stmt_if = (IF, assignment >> e, block >> trueBlock) ^ newIfStatement(e, trueBlock)
	
	stmt_return = (RETURN, optional_assignment >> e, stmt_modifier >> m) ^ ReturnStatement(Expression: e, Modifier: m)
	
	optional_assignment = assignment | ""

	stmt_expression = ((multi_assignment | assignment) >> e, stmt_modifier >> m) ^ ExpressionStatement(Expression: e, Modifier: m)
	
	multi_assignment = (expression >> l, ASSIGN >> op, rvalue >> r) ^ newInfixExpression(op, l, r)
	
	rvalue = assignment_list >> items ^ newRValue(items)
	
	list_of assignment
	
	infixr assignment, (ASSIGN | ASSIGN_INPLACE), expression
	
	expression = generator_expression | or_expression
	
	generator_expression = (
		or_expression >> projection, FOR, declaration_list >> dl, IN, rvalue >> e, ((stmt_modifier_node >> f) | "")
	) ^ newGeneratorExpression(projection, dl, e, f)
	
	infix or_expression, OR, and_expression
	
	infix and_expression, AND, not_expression
	
	prefix not_expression, NOT, membership_expression
	
	infix membership_expression, (IN | ((NOT, IN) ^ makeToken("not in"))), identity_test_expression
	
	infix identity_test_expression, (((IS, NOT) ^ makeToken("is not")) | IS), comparison
	
	infix comparison, (EQUALITY | INEQUALITY | GREATER_THAN | GREATER_THAN_EQ | LESS_THAN | LESS_THAN_EQ), bitwise_or_expression
	
	infix bitwise_or_expression, BITWISE_OR, bitwise_xor_expression
	
	infix bitwise_xor_expression, XOR, bitwise_and_expression
	
	infix bitwise_and_expression, BITWISE_AND, bitwise_shift_expression
	
	infix bitwise_shift_expression, (BITWISE_SHIFT_LEFT | BITWISE_SHIFT_RIGHT), term
	
	infix term, (PLUS | MINUS), factor

	infix factor, (STAR | DIVISION | MODULUS), signalled_expression
	
	prefix signalled_expression, (MINUS | INCREMENT | DECREMENT), ones_complement_expression
	
	prefix ones_complement_expression, ONES_COMPLEMENT, exponentiation_expression
	
	infix exponentiation_expression, EXPONENTIATION, try_cast
	
	try_cast = ((try_cast >> e, AS, type_reference >> typeRef) ^ TryCastExpression(Target: e, Type: typeRef)) | member_reference
	
	member_reference = ((member_reference >> e, DOT, ID >> name) ^ newMemberReference(e, name)) | slicing
	
	slicing = ((member_reference >> e, LBRACK, slice_list >> indices, RBRACK) ^ newSlicing(e, indices)) | invocation

	slice = (
			(
				(COLON ^ OmittedExpression.Default) >> begin,
				(expression | ("" ^ OmittedExpression.Default)) >> end,
				(omitted_expression | "") >> step
			)
			|
			(
				expression >> begin,
				((omitted_expression >> end,
					((omitted_expression >> step) | ""))
				| "")
			)
		) ^ newSlice(begin, end, step)
			
	list_of expression
	
	list_of declaration
	
	list_of type_reference
		
	list_of slice
				
	omitted_expression = (COLON, expression) | (COLON ^ OmittedExpression.Default)
		
	invocation = ((member_reference >> target, invocation_arguments >> args) ^ newInvocation(target, args)) \
		| atom
		
	invocation_arguments = (LPAREN, optional_invocation_argument_list >> args, RPAREN) ^ args
	
	invocation_argument = named_argument | assignment
	
	list_of invocation_argument
	
	named_argument = (ID >> name, COLON, assignment >> value) ^ newNamedArgument(name, value)
	
	type_reference = type_reference_simple | type_reference_array | type_reference_callable
	
	type_reference_callable = (
		CALLABLE, LPAREN, optional_type_reference_list >> params, RPAREN, optional_type >> type
	) ^ newCallableTypeReference(params, type)
	
	type_reference_array = (LPAREN, ranked_type_reference >> tr, RPAREN) ^ tr
	
	type_reference_simple = (qualified_name >> qname) ^ SimpleTypeReference(Name: qname)
	
	atom = integer | boolean | reference | array_literal | list_literal \
		| string_interpolation | string_literal | null_literal | parenthesized_expression  \
		| self_literal | super_literal | quasi_quote
		
	quasi_quote = quasi_quote_member | quasi_quote_module | quasi_quote_expression | quasi_quote_stmt
	
	quasi_quote_module = (QQ_BEGIN, INDENT, module >> m, DEDENT, QQ_END) ^ newQuasiquoteBlock(m)
	
	quasi_quote_member = (QQ_BEGIN, INDENT, class_member >> m, DEDENT, QQ_END) ^ newQuasiquoteBlock(m)
	
	quasi_quote_expression = (QQ_BEGIN, rvalue >> s, QQ_END) ^ newQuasiquoteExpression(s)
	
	quasi_quote_stmt = (QQ_BEGIN, (qq_return | qq_macro) >> s, QQ_END) ^ newQuasiquoteExpression(s)
	
	qq_return = (RETURN, optional_assignment >> e) ^ ReturnStatement(Expression: e)
	
	qq_macro = (ID >> name, assignment_list >> args) ^ newMacro(name, args, null, null)
	
	parenthesized_expression = (LPAREN, assignment >> e, RPAREN) ^ e
		
	null_literal = NULL ^ [| null |]
	
	super_literal = SUPER ^ [| super |]
	
	self_literal = SELF ^ [| self |]
	
	string_literal = (SQS >> s) ^ newStringLiteral(s)
	
	string_interpolation = (
		DQ,
		++(
			((++(~('"' | '$'), string_char) >> s) ^ StringLiteralExpression(makeString(s)))
			| (('${', expression >> v, --space, '}') ^ v)
			| ('$', atom)
			) >> items,
		DQ) ^ newStringInterpolation(items)
		
	string_char = ('\\', ('\\' | '$')) | (~'\\', _)
	
	array_literal = array_literal_empty | array_literal_single | array_literal_multi
			
	array_literal_empty = (LPAREN, array_literal_type >> type, COMMA, RPAREN) ^ newArrayLiteral(type, [])
	
	array_literal_single = (LPAREN, array_literal_type >> type, assignment >> e, COMMA, RPAREN) ^ newArrayLiteral(type, [e])
	
	array_literal_multi = (LPAREN, array_literal_type >> type, assignment >> e, ++(COMMA, assignment) >> tail, (COMMA | ""), RPAREN) ^ newArrayLiteral(type, prepend(e, tail))
			
	array_literal_type = ((OF, ranked_type_reference >> type, COLON) | "") ^ type
	
	ranked_type_reference = ((type_reference >> type), ((COMMA,  integer >> rank) | "")) ^ ArrayTypeReference(ElementType: type, Rank: rank) 
	
	list_literal = (LBRACK, optional_expression_list >> items, RBRACK) ^ newListLiteral(items)
		
	reference = ID >> r ^ newReference(r) 
	
	integer = (NUM >> n ^ newInteger(n, NumberStyles.None)) \
		| (HEXNUM >> n ^ newInteger(n, NumberStyles.HexNumber))
	
	boolean = true_literal | false_literal
	
	true_literal = TRUE ^ [| true |]
	
	false_literal = FALSE ^ [| false |]
	
	eol = ++EOL | ~_	
	
