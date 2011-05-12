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
	
	if len(list_of.Arguments) == 2:
		rule, separator = list_of.Arguments
	else:
		rule, separator = list_of.Arguments[0], [| COMMA |]
	
	block as Block = list_of.ParentNode
	
	listRuleName = ReferenceExpression(Name: "${rule}_list")
	listRule = [| $listRuleName = ((($rule >> first), ++(($separator, $rule >> e) ^ e) >> rest) ^ prepend(first, rest)) | ($rule >> v ^ [v]) |]
	block.Add(listRule)
	
	optionalRuleName = ReferenceExpression(Name: "optional_${rule}_list")
	optionalListRule = [| $optionalRuleName = $listRuleName | ("" ^ []) |]
	block.Add(optionalListRule)
	
ometa BooParser < WhitespaceSensitiveTokenizer:

	tokens:
		qq_begin = "[|"
		qq_end = "|]"
		splice_begin = "$"
		equality = "=="
		inequality = "!="
		assign = "="
		assign_inplace = "+=" | "-=" | "*=" | "/=" | "%=" | "^=" | "&=" | "|=" | "<<=" | ">>="
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
		semicolon = ";"
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
		sq = "'"
		
		id = ((letter | '_') >> p, --(letter | digit | '_') >> s) ^ makeString(p, s)

	space = line_continuation | multi_line_comment | line_comment | super
	
	sqs = (SQ, --( sqs_esc | (~('\'' | '\\' | '\r' | '\n'), _)) >> s, SQ) ^ makeString(s)		

	dqs = (DQ, --( dqs_esc | (~('"' | '\\' | '\r' | '\n'), _)) >> s, DQ) ^ makeString(s)		

	tqs = (TDQ, --(~tdq, ( (('\\', '$') ^ '$')| _)) >> s, TDQ) ^ makeString(s)			
	
	sqs_esc =  '\\', ( sesc | '\'' )

	dqs_esc = '\\', ( sesc | '"' | '$')

	sesc =  ("r" ^ "\r") | ("n" ^ "\n") | ("t" ^ "\t") | ("a" ^ "\a") | ("b" ^ "\b") | ("f" ^ "\f") \
		| ("0" ^ "\0") | ("\\" ^ "\\") \
		| ("u", (hex_digit >> h1, hex_digit >> h2, hex_digit >> h3, hex_digit >> h4) ^ getUnicodeChar([h1, h2, h3, h4]))
	
	empty_line = ending_spaces, newline	
	
	ending_spaces = --end_space >> value ^ value
	
	end_space =  semicolon | space
	
	line_continuation = "\\", newline
	
	multi_line_comment = "/*", --(~"*/", (multi_line_comment | _)), "*/"
	
	line_comment = ('#' | "//"), --(~newline, _)
		
	hex_digit = _ >> c as char and ((c >= char('a') and c <= char('f')) or (c >= char('A') and c <= char('F'))) 
		
	keywords "abstract", "and", "as", "callable", "cast", "class", "constructor", "def", "do", "elif", "else", \
		"ensure", "enum", "event", "except", "failure", "false", "final", "for", "from", "goto", "if", "import", \
		"interface", "internal", "in", "isa", "is", "namespace", "not", "null", "of", "or", "override", \
		"pass", "private", "protected", "public", "raise", "return", "self", "static", "struct", "super", \
		"then", "transient", "true", "try", "typeof", "unless", "virtual", "while", "yield"
	
	keyword[expected] = ((KW >> t) and (expected is tokenValue(t))) ^ t
	
	module = (
		--EOL,
		((tqs >> s , EOL) | ""),	
		--EOL,
		((namespace_declaration >> ns , EOL) | ""),		
		--import_declaration >> ids,
		--module_member >> members,
		--stmt >> stmts,
		--EOL
	) ^ newModule(ns, s, ids, members, stmts)
	
	namespace_declaration = (NAMESPACE, qualified_name)

	
	
	import_declaration = ( (IMPORT, qualified_name >> qn), (((FROM, (dqs | sqs | qualified_name)) | "") >> assembly), ( (AS, ID) | "") >> alias, eol) ^ newImport(qn, assembly, alias)
	
	qualified_name = (ID >> qualifier, --((DOT, id >> n) ^ n) >> suffix)^ buildQName(qualifier, suffix) 
	
	module_member = assembly_attribute | type_def | method | (~(~~(ID, AS), stmt_declaration), ~stmt_expression, ~stmt_goto, stmt_macro)
	
	type_def = class_def | struct_def | interface_def | enum_def | callable_def
	
	callable_def = (member_modifiers >> mod, CALLABLE, ID >> name, optional_generic_parameters >> genericParameters , method_parameters >> parameters, optional_type >> type, eol) ^ newCallable(mod, name, genericParameters, parameters, type)
	
	class_def = (
		attributes >> attrs,
		member_modifiers >> mod,
		CLASS, ID >> className, optional_generic_parameters >> genericParameters, super_types >> superTypes, begin_block, class_body >> body, end_block
	) ^ newClass(attrs, mod, className, genericParameters, superTypes, body)

	struct_def = (
		attributes >> attrs,
		member_modifiers >> mod,
		STRUCT, ID >> structName, optional_generic_parameters >> genericParameters, super_types >> superTypes, begin_block, struct_body >> body, end_block
	) ^ newStruct(attrs, mod, structName, genericParameters, superTypes, body)


	interface_def = (
		attributes >> attrs,
		member_modifiers >> mod,
		INTERFACE, ID >> name, optional_generic_parameters >> genericParameters, super_types >> superTypes, begin_block, interface_body >> body, end_block
	) ^ newInterface(attrs, mod, name, genericParameters, superTypes, body)
	
	enum_def = (
		attributes >> attrs, 
		member_modifiers >> mod,
		ENUM, ID >> name, begin_block, enum_body >> body, end_block
	) ^ newEnum(attrs, mod, name, body)
	
	enum_body = (++enum_field >> fields ^ fields) | (PASS, eol ^ null)
	
	enum_field = (attributes >> attrs, ID >> name, ((ASSIGN, expression >> e) | ""), eol) ^ newEnumField(attrs, name, e)
	
	super_types = ((LPAREN, optional_type_reference_list >> types, RPAREN) ^ types) | ""
	
	class_body = no_member | (++class_member >> members ^ members)
	
	struct_body = no_member | (++struct_member >> members ^ members)
	
	interface_body = no_member | (++interface_member >> members ^ members)
	
	no_member = (PASS, eol) ^ null
	
	class_member = type_def | property_def | constructor_method | method | field | event_def
	
	struct_member = constructor_method | method | field
	
	interface_member = property_def | method_signature
	
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
	
	method_signature = (
		attributes >> attrs,
		member_modifiers >> mod,
		DEF, ID >> name,
		optional_generic_parameters >> genericParameters,
		method_parameters >> parameters,
		attributes >> returnTypeAttributes, optional_type >> type, eol
	) ^ newGenericMethod(attrs, mod, name, genericParameters, parameters, returnTypeAttributes, type, null)	
	
	
	property_parameters = ((LBRACK, parameter_list >> parameters, RBRACK) | "") ^ parameters
	
	property_getter = accessor["get"]
	
	property_setter = accessor["set"]
	
	accessor[key] = (
		attributes >> attrs,
		member_modifiers >> mod, 
		(ID >> name and (tokenValue(name) == key)),
		block >> body
	) ^ newMethod(attrs, mod, name, [[],null], null, null, body)
	
	field = (
		attributes >> attrs,
		member_modifiers >> mod,
		ID >> name, optional_type >> type, field_initializer >> initializer
	) ^ newField(attrs, mod, name, type, initializer)

	field_initializer = (ASSIGN, block_expression) | ((ASSIGN, rvalue >> v, eol) ^ v) | eol
	
	member_modifiers = --(
		(PRIVATE ^ TypeMemberModifiers.Private)
		| (PUBLIC ^ TypeMemberModifiers.Public)
		| (INTERNAL ^ TypeMemberModifiers.Internal)
		| (PROTECTED ^ TypeMemberModifiers.Protected)
		| (FINAL ^ TypeMemberModifiers.Final)
		| (STATIC ^ TypeMemberModifiers.Static)
		| (VIRTUAL ^ TypeMemberModifiers.Virtual)
		| (OVERRIDE ^ TypeMemberModifiers.Override)
		| (TRANSIENT ^ TypeMemberModifiers.Transient)
		| (ABSTRACT ^ TypeMemberModifiers.Abstract)
	) >> all ^ all
	
	method = (
		attributes >> attrs,
		member_modifiers >> mod,
		DEF, ID >> name,
		optional_generic_parameters >> genericParameters,
		method_parameters >> parameters,
		attributes >> returnTypeAttributes, optional_type >> type,
		block >> body
	) ^ newGenericMethod(attrs, mod, name, genericParameters, parameters, returnTypeAttributes, type, body)


	constructor_method = (
		attributes >> attrs,
		member_modifiers >> mod,
		DEF, CONSTRUCTOR,
		optional_generic_parameters >> genericParameters,
		method_parameters >> parameters,
		block >> body
	) ^ newConstructor(attrs, mod, genericParameters, parameters, body)


	method_parameters = (LPAREN, \
				((parameter_list >> parameters, COMMA, param_array >> paramArray) | (param_array >> paramArray) | (optional_parameter_list >> parameters) ), \
				RPAREN) ^ [parameters, paramArray]
	
	param_array = ((attributes >> attrs, STAR, ID >> name, optional_array_type >> type) ^ newParameterDeclaration(attrs, name, type))
	
	optional_array_type = (AS, type_reference_array) | ""
	
	optional_generic_parameters = generic_parameters | ""
	
	generic_parameters = (LBRACK, (OF | ""), generic_parameter_list >> parameters, RBRACK) ^ parameters
	
	generic_parameter = (ID >> name, optional_generic_parameter_constraints >> genericParameterConstraints) ^ newGenericParameterDeclaration(name, genericParameterConstraints)
	
	optional_generic_parameter_constraints = generic_parameter_constraints | ""
	
	generic_parameter_constraints = (LPAREN, generic_parameter_constraint_list >> constraints, RPAREN) ^ constraints
	
	generic_parameter_constraint = ( (CLASS | STRUCT | CONSTRUCTOR) >> constraint ^ newGenericParameterConstraint(constraint) ) | type_reference
	
	list_of generic_parameter_constraint
	
	list_of generic_parameter
	
	list_of parameter
	
	assembly_attribute = (
		LBRACK, (ID >> name and (tokenValue(name) == "assembly")), COLON,
		attribute_list >> value, 
		RBRACK, eol) ^ value
	
	attributes = --((LBRACK, attribute_list >> value, RBRACK, --EOL) ^ value) >> all ^ all
	
	attribute = (qualified_name >> name, optional_invocation_arguments >> args) ^ newAttribute(name, args)
	
	list_of attribute
	
	parameter = (attributes >> attrs, ID >> name, optional_type >> type) ^ newParameterDeclaration(attrs, name, type)

	optional_type = (AS, type_reference) | ""
	
	block = empty_block | multi_line_block | multi_line_block_with_doc | single_line_block
	
	empty_block = (begin_block, (PASS, eol), end_block) ^ Block()
	
	multi_line_block = (begin_block, ++stmt >> stmts, end_block)  ^ newBlock(stmts)
	
	multi_line_block_with_doc = (begin_block_with_doc >> doc, ++stmt >> stmts, end_block)  ^ [doc, newBlock(stmts)]
	
	single_line_block = (COLON, stmt_line >> line) ^ newBlock(line)
	
	begin_block = COLON, INDENT
	
	begin_block_with_doc = (COLON,
		--EOL,
		tqs >> s,
		INDENT) ^ s	
	
	end_block = DEDENT
	
	stmt = stmt_block | stmt_line 
	
	stmt_line = (~~(ID, AS), stmt_declaration) \
		| stmt_expression \
		| stmt_goto \
		| stmt_macro \
		| stmt_return \
		| stmt_yield \
		| stmt_raise \
		| stmt_unpack \
		| stmt_try
		
	stmt_unpack = (declaration_list >> declarations, ASSIGN, rvalue >> e, stmt_modifier >> m) ^ newUnpackStatement(declarations, e, m)
		
	stmt_raise = (RAISE, expression >> e, stmt_modifier >> m) ^ RaiseStatement(Exception: e, Modifier: m)
		
	stmt_macro = (ID >> name, optional_assignment_list >> args, ((block >> b) | (stmt_modifier >> m))) ^ newMacro(name, args, b, m)

	stmt_yield = (YIELD, assignment >> e, stmt_modifier >> m) ^ YieldStatement(Expression: e, Modifier: m)
	
	stmt_modifier = (((stmt_modifier_node | "") >> value, (eol|SEMICOLON)) ^ value)
	
	stmt_try = (TRY, block >> protectedBlock, \
		optional_exception_handler_list >> handlers, \
		((FAILURE, block >> failureBlock) | ""), \
		((ENSURE, block >> ensureBlock) | "")) ^ newTryStatement(protectedBlock, handlers, failureBlock, ensureBlock)
	
	exception_handler = (EXCEPT, (declaration | "") >> d, block >> b) ^ ExceptionHandler(Block: b, Declaration: d)
	
	list_of exception_handler
	
	stmt_goto = ((GOTO, ID >> label, stmt_modifier >> m) ^ newGotoStatement(label, m)) | ((COLON, ID >> label, eol) ^ LabelStatement(Name: tokenValue(label)))
	
	stmt_modifier_node = (
		stmt_modifier_type >> t,
		assignment >> e
	) ^ newStatementModifier(t, e)
	
	stmt_modifier_type = (IF ^ StatementModifierType.If) | (UNLESS ^ StatementModifierType.Unless)
	
	stmt_declaration = (declaration >> d,
			(ASSIGN, block_expression >> e)
			| ((ASSIGN, rvalue >> e), eol)
			| eol
		) ^ newDeclarationStatement(d, e)
	
	declaration = (ID >> name, optional_type >> typeRef) ^ newDeclaration(name, typeRef)

	stmt_block = stmt_if | stmt_unless | stmt_for | stmt_while

	stmt_for = (FOR, declaration_list >> dl, IN, rvalue >> e, block >> body, or_block >> orBlock, then_block >> thenBlock) ^ newForStatement(dl, e, body, orBlock, thenBlock)
	
	stmt_while = (WHILE, assignment >> e, block >> body, or_block >> orBlock, then_block >> thenBlock) ^ newWhileStatement(e, body, orBlock, thenBlock)

	or_block = ((OR, block >> orBlock) ^ orBlock) | ( "" ^ null)
	
	then_block = ((THEN, block >> thenBlock) ^ thenBlock) | ( "" ^ null)	
	
	stmt_if = (IF, assignment >> e, block >> trueBlock, false_block >> falseBlock) ^ newIfStatement(e, trueBlock, falseBlock)
	
	stmt_unless	= (UNLESS, assignment >> e, block >> condition) ^ newUnlessStatement(e, condition)
	
	false_block = ((ELIF, assignment >> e, block >> trueBlock, false_block >> falseBlock) ^ newBlock(newIfStatement(e, trueBlock, falseBlock))) | \
		((ELSE, block >> falseBlock) ^ falseBlock) | ( "" ^ null)
	
	stmt_return = (
		RETURN, ((optional_assignment >> e, stmt_modifier >> m) | (block_expression >> e))
		) ^ ReturnStatement(Expression: e, Modifier: m)
	
	optional_assignment = assignment | ""
	
	stmt_expression_block = (expression >> l, (ASSIGN | ASSIGN_INPLACE) >> op, block_expression >> r) ^ ExpressionStatement(newInfixExpression(op, l, r))
	
	block_expression = invocation_with_block | closure_block | dsl_friendly_invocation
	
	invocation_with_block = (member_reference >> e and (e isa MethodInvocationExpression), \
		(closure_block | (block >> b ^ newBlockExpression([[], null], b))) >> c ^ newInvocationWithBlock(e, c) ) 

	dsl_friendly_invocation = (member_reference >> e and ((e isa MemberReferenceExpression) or (e isa ReferenceExpression)), \
		(block) >> c) ^ newInvocation(e, [BlockExpression(Body: c)], null)
	
	closure_block = ((DEF | DO), optional_parameters >> parameters, block >> body) ^ newBlockExpression(parameters, body)
	
	optional_parameters = method_parameters | ("" ^ [[], null])

	stmt_expression = stmt_expression_block \
		| ((block_expression >> e) ^ ExpressionStatement(Expression: e)) \
		| (((multi_assignment | assignment) >> e, stmt_modifier >> m) ^ ExpressionStatement(Expression: e, Modifier: m))
	
	multi_assignment = (expression >> l, ASSIGN >> op, rvalue >> r) ^ newInfixExpression(op, l, r)
	
	rvalue = assignment_list >> items ^ newRValue(items)
	
	list_of assignment
	
	infixr assignment, (ASSIGN | ASSIGN_INPLACE), expression
	
	expression = generator_expression | conditional_expression
	
	generator_expression = (
		or_expression >> projection,
		++generator_expression_body >> body
	) ^ newGeneratorExpression(projection, body)
	
	generator_expression_body = (FOR, declaration_list >> dl, IN, conditional_expression >> e, optional_filter >> f) ^ newGeneratorExpressionBody(dl, e, f)
	
	optional_filter = ((stmt_modifier_type >> t, or_expression >> e) ^ newStatementModifier(t, e)) | ""
	
	conditional_expression = (
		(or_expression >> trueValue, IF, conditional_expression >> condition, ELSE, conditional_expression >> falseValue) ^  newConditionalExpression(condition, trueValue, falseValue)
	) | or_expression
	
	infix or_expression, OR, and_expression
	
	infix and_expression, AND, not_expression
	
	prefix not_expression, NOT, explode_operator
	
	prefix explode_operator, STAR , membership_expression
	
	infix membership_expression, (IN | ((NOT, IN) ^ makeToken("not in"))), identity_test_expression
	
	infix identity_test_expression, (((IS, NOT) ^ makeToken("is not")) | IS), isa_expression
	
	isa_expression = (comparison >> l, ISA >> op, type_reference >> type) ^ newInfixExpression(op, l, newTypeofExpression(type))  | comparison 
	
	infix comparison, (EQUALITY | INEQUALITY | GREATER_THAN | GREATER_THAN_EQ | LESS_THAN | LESS_THAN_EQ), bitwise_or_expression
	
	infix bitwise_or_expression, BITWISE_OR, bitwise_xor_expression
	
	infix bitwise_xor_expression, XOR, bitwise_and_expression
	
	infix bitwise_and_expression, BITWISE_AND, term
	
	infix term, (PLUS | MINUS), factor

	infix factor, (STAR | DIVISION | MODULUS), bitwise_shift_expression

	infix bitwise_shift_expression, (BITWISE_SHIFT_LEFT | BITWISE_SHIFT_RIGHT), signalled_expression

	prefix signalled_expression, (MINUS | INCREMENT | DECREMENT), ones_complement_expression
	
	prefix ones_complement_expression, ONES_COMPLEMENT, exponentiation_expression
	
	infix exponentiation_expression, EXPONENTIATION, try_cast
	
	try_cast = ((try_cast >> e, AS, type_reference >> typeRef) ^ TryCastExpression(Target: e, Type: typeRef)) | cast_operator 
	
	cast_operator = ((cast_operator >> e, CAST, type_reference >> typeRef) ^ CastExpression(Target: e, Type: typeRef)) | member_reference
	
	member_reference = (((member_reference >> e, DOT, ID >> name) ^ newMemberReference(e, name)) | slicing) >> e, (INCREMENT | DECREMENT | "") >> postOp ^ addSuffixUnaryOperator(e, postOp)
	
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
		
	invocation = at_operator | collection_initialization | invocation_expression | atom
	
	at_operator = ("@", invocation_arguments >> args) ^ newInvocation(ReferenceExpression("@"), args, null)
	
	invocation_expression = (member_reference >> target, optional_generic_arguments >> generic_args, invocation_arguments >> args) ^ newInvocation(target, args, generic_args)
		
	invocation_arguments = (LPAREN, optional_invocation_argument_list >> args, RPAREN) ^ args
	
	optional_invocation_arguments = invocation_arguments | ""
	
	invocation_argument = named_argument | assignment
	
	list_of invocation_argument
	
	named_argument = (ID >> name, COLON, assignment >> value) ^ newNamedArgument(name, value)
	
	type_reference = (type_reference_splice \
		| type_reference_generic_definition \
		| type_reference_generic \
		| type_reference_simple \
		| type_reference_array \
		| type_reference_callable) >> t, --star >> s ^ checkEnumerableTypeShortcut(t, s)  
		
	type_reference_splice = SPLICE_BEGIN, atom >> e ^ SpliceTypeReference(Expression: e)
	
	splice_expression = SPLICE_BEGIN, atom >> e ^ SpliceExpression(Expression: e)
	
	type_reference_generic_definition = (qualified_name >> qname, generic_placeholders >> placeholders) ^ newGenericTypeDefinitionReference(qname, placeholders)

	generic_placeholders = ((LBRACK, OF, STAR_list >> placeholders, RBRACK) ^ placeholders) | ( (OF, STAR_list >> placeholders) ^ placeholders)
	
	list_of STAR
		
	type_reference_generic = (qualified_name >> qname, generic_arguments >> args) ^ newGenericTypeReference(qname, args)
	
	generic_arguments = ((LBRACK, (OF | ""), type_reference_list >> args, RBRACK) ^ args) \
		| ((OF, type_reference >> arg) ^ [arg])
		
	optional_generic_arguments = generic_arguments | ""
	
	type_reference_callable = (
		CALLABLE, LPAREN, \
		((type_reference_list >> params, COMMA, param_array_reference >> paramArray) | (param_array_reference >> paramArray) | (optional_type_reference_list >> params) ), \
		RPAREN, optional_type >> type
	) ^ newCallableTypeReference(params, paramArray, type) | ((CALLABLE)^ SimpleTypeReference("callable"))
	
	param_array_reference = ((STAR, type_reference >> type) ^ newParameterDeclaration(null, makeToken("arg0"), type))
	
	type_reference_array = (LPAREN, ranked_type_reference >> tr, RPAREN) ^ tr
	
	type_reference_simple = (qualified_name >> qname) ^ SimpleTypeReference(Name: qname)
	
	atom = time_span | float | integer | boolean | reference | array_literal | list_literal \
		| string_interpolation | string_literal | reg_exp_string | null_literal | parenthesized_expression  \
		| self_literal | super_literal | quasi_quote | closure | hash_literal \
		| type_literal | splice_expression
		
	type_literal = (TYPEOF, LPAREN, type_reference >> type, RPAREN) ^ newTypeofExpression(type)
		
	closure = (LBRACE, closure_parameters >> parameters, closure_stmt_list >> body, RBRACE) ^ newBlockExpression(parameters, newBlock(body))
	
	closure_parameters = ((optional_parameter_list >> parameters, BITWISE_OR) ^ [parameters, null]) | ("" ^ [[],null])
	
	list_of closure_stmt, SEMICOLON
	
	closure_stmt = closure_stmt_expression | closure_stmt_macro | closure_stmt_return | closure_stmt_raise | closure_stmt_unpack
	
	closure_stmt_macro = (ID >> name, assignment_list >> args, closure_stmt_modifier >> m) ^ newMacro(name, args, null, m)
	
	closure_stmt_modifier = stmt_modifier_node | ~~(RBRACE | SEMICOLON)
	
	closure_stmt_return = (RETURN, (rvalue | "") >> e, closure_stmt_modifier >> m) ^ ReturnStatement(Expression: e, Modifier: m)
	
	closure_stmt_raise = (RAISE, expression >> e, closure_stmt_modifier >> m) ^ RaiseStatement(Exception: e, Modifier: m)
	
	closure_stmt_expression = (assignment >> e, closure_stmt_modifier >> m) ^ ExpressionStatement(Expression: e, Modifier: m)
	
	closure_stmt_unpack = (declaration_list >> declarations, ASSIGN, rvalue >> e, closure_stmt_modifier >> m) ^ newUnpackStatement(declarations, e, m)		
	
	optional_stmt_modifier_node = stmt_modifier_node | ""
		
	quasi_quote = quasi_quote_member | quasi_quote_module | quasi_quote_expression | quasi_quote_stmt
	
	quasi_quote_module = (QQ_BEGIN, INDENT, module >> m, DEDENT, QQ_END) ^ newQuasiquoteBlock(m)
	
	quasi_quote_member = (QQ_BEGIN, INDENT, class_member >> m, DEDENT, QQ_END) ^ newQuasiquoteBlock(m)
	
	quasi_quote_expression = (QQ_BEGIN, rvalue >> s, QQ_END) ^ newQuasiquoteExpression(s)
	
	quasi_quote_stmt = (QQ_BEGIN, (qq_return | qq_macro) >> s, QQ_END) ^ newQuasiquoteExpression(s)
	
	qq_return = (RETURN, optional_assignment >> e, optional_stmt_modifier_node >> m) ^ ReturnStatement(Expression: e, Modifier: m)
	
	qq_macro = (ID >> name, assignment_list >> args, optional_stmt_modifier_node >> m) ^ newMacro(name, args, null, m)
	
	parenthesized_expression = (LPAREN, assignment >> e, RPAREN) ^ e
		
	null_literal = NULL ^ [| null |]
	
	super_literal = SUPER ^ [| super |]
	
	self_literal = SELF ^ [| self |]
	
	string_literal = string_interpolation| ( ((tqs | dqs | sqs) >> s) ^ newStringLiteral(s))

	string_interpolation = (
		DQ,
		--(
			((++(~('"' | '$'), string_char) >> s) ^ StringLiteralExpression(makeString(s)))
			| (('${', expression >> v, --space, '}') ^ v)
			| ('$', atom)
			) >> items,
		DQ) ^ newStringInterpolation(items)
		
	reg_exp_string = ( (((~"/*","/") | "@/"), (--(~"/", _) >> s), "/")  ) ^ RELiteralExpression(makeString("/", s, "/"))		
		
	string_char = ('\\', ('\\' | '$')) | (~'\\', _)
	
	array_literal = array_literal_empty | array_literal_single | array_literal_multi
			
	array_literal_empty = (LPAREN, array_literal_type >> type, COMMA, RPAREN) ^ newArrayLiteral(type, [])
	
	array_literal_single = (LPAREN, array_literal_type >> type, assignment >> e, COMMA, RPAREN) ^ newArrayLiteral(type, [e])
	
	array_literal_multi = (LPAREN, array_literal_type >> type, assignment >> e, ++(COMMA, assignment) >> tail, (COMMA | ""), RPAREN) ^ newArrayLiteral(type, prepend(e, tail))
			
	array_literal_type = ((OF, ranked_type_reference >> type, COLON) | "") ^ type

	ranked_type_reference = ((type_reference >> type), ((COMMA,  integer >> rank) | "")) ^ ArrayTypeReference(ElementType: type, Rank: rank) 
	
	list_literal = (LBRACK, optional_expression_list >> items, optional_comma, RBRACK) ^ newListLiteral(items)
	
	hash_literal = (LBRACE, optional_expression_pair_list >> items, optional_comma, RBRACE) ^ newHashLiteral(items)
	
	initialization_list_literal = (LBRACE, optional_expression_list >> items, optional_comma, RBRACE) ^ newListLiteral(items)
	
	collection_initialization = invocation_expression >> e, (initialization_list_literal | hash_literal) >> i ^ newCollectionInitialization(e, i)
	
	optional_comma = COMMA | ""
	
	expression_pair = (assignment >> first, COLON, assignment >> second) ^ ExpressionPair(First: first, Second: second)
	
	list_of expression_pair

	reference = ID >> r ^ newReference(r) 
	
	time_span = ((integer | float) >> f, ("ms" | 's' | 'm' | 'h' | 'd') >> tu) ^ newTimeSpanLiteral(f, tu)
	
	integer = ((MINUS | "") >> sign, NUM >> n and (IsValidLong(sign, n)), ("L" | "l" | "") >> suffix ^ newInteger(sign, n, NumberStyles.AllowLeadingSign, suffix)) \
		| ((MINUS | "") >> sign, (HEXNUM >> n and (IsValidHexLong(sign, n))), ("L" | "l" | "") >> suffix ^ newInteger(sign, n, NumberStyles.HexNumber, suffix))
	
	float = ( (fractional_constant >> n, (exponent_part | "") >> e , floating_suffix ) ^ newFloat(makeString(n,e))) | ((NUM >> n, exponent_part >> e, floating_suffix)  ^ newFloat(makeString(tokenValue(n),e)))

	fractional_constant = ((NUM >> a , DOT , NUM >> b) ^ makeString(tokenValue(a),".",tokenValue(b))) | ( (DOT , NUM >> b) ^ makeString(".",tokenValue(b)) ) | ( (NUM >> a , DOT, ~(ID)) ^ makeString(tokenValue(a), ".") )
    
	exponent_part = ( ("e" | "E") , exposignopt >> e , NUM >> d ) ^ makeString("e", e, tokenValue(d))

	exposignopt = ( (PLUS | MINUS) >> e ^ makeString(tokenValue(e)) ) | ""
	
	floating_suffix = "f" | "l" | "F" | "L" | ""
	
	boolean = true_literal | false_literal
	
	true_literal = TRUE ^ [| true |]
	
	false_literal = FALSE ^ [| false |]
	
	eol = (++EOL | ~_) ^ null

