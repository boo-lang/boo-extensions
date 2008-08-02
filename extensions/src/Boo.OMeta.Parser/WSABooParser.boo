namespace Boo.OMeta.Parser
	
import Boo.OMeta
	
ometa WSABooParser < BooParser:
	scanner = (empty_lines ^ makeToken("eol")) | ((--whitespace, tokens >> t) ^ t)
	
	keywords = "end" | super
	
	begin_block = COLON, eol
	end_block = keyword["end"], eol
	