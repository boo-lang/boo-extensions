namespace Boo.OMeta.Parser
	
import Boo.OMeta
	
ometa WSABooParser < BooParser:
	scanner = (emptyLines ^ makeToken("eol")) | ((--whitespace, tokens >> t) ^ t)
	
	keywords = "end" | super
	
	beginBlock = COLON, eol
	endBlock = keyword["end"], eol
	