namespace Boo.OMeta.Parser
	
import Boo.OMeta
import Boo.Lang.Compiler.Ast
	
ometa WSABooParser < BooParser:
	scanner = (empty_lines ^ makeToken("eol")) | ((--whitespace, tokens >> t) ^ t)
	
	keywords = "end" | super
	
	begin_block = COLON, eol
	end_block = keyword["end"], eol
	empty_block = (begin_block, end_block) ^ Block()
	
	INDENT = eol | ""
	DEDENT = eol | ""
	
	class_body = (--class_member >> members ^ members)
	struct_body = (--struct_member >> members ^ members)
	interface_body = (--interface_member >> members ^ members)
	