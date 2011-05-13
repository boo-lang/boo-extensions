namespace Boo.OMeta.Parser
	
import Boo.OMeta
import Boo.Lang.Compiler.Ast
	
ometa WSABooParser < BooParser:
	scanner = (empty_lines ^ makeToken("eol")) | ((--space, tokens >> t) ^ t)

	keywords = "end" | super
	
	begin_block = COLON, eol
	end_block = (keyword["end"], eol) | (~~ELSE) | (~~ELIF) | (~~(OR, COLON)) | (~~THEN)
	empty_block = (begin_block, end_block) ^ Block()
	
	member_reference = (((member_reference >> e, enterWhitespaceAgnosticRegion, DOT, ID >> name, leaveWhitespaceAgnosticRegion) \
		^ newMemberReference(e, name)) | slicing) >> e, (INCREMENT | DECREMENT | "") >> postOp ^ addSuffixUnaryOperator(e, postOp)
	
	INDENT = eol | ""
	DEDENT = eol | ""
	
	class_body = (--class_member >> members ^ members)
	struct_body = (--struct_member >> members ^ members)
	interface_body = (--interface_member >> members ^ members)

	stmt_macro = (PASS >> name, optional_assignment_list >> args, ((block >> b) | (stmt_modifier >> m))) ^ newMacro(name, args, b, m) | super
