namespace Paragraphs

import Boo.Pegs

indent = ""
def ods(m):
	print indent, m

peg:
	document = ++[para, line], eof
	para = inset, enter, line, --((@inset, inset) & para / (@inset, line)), leave
	inset = ++[" ", "\t"]
	line = ++(not "\n", any()), { ods $text }, eol
	eol = "\n"
	eof = not any()
	
	enter = do:
		ods "{"
		indent += "\t"
		
	leave = do:
		indent = indent[:-1]
		ods "}"
		
	
s = """first line
second line
   p11
   p12
   	p21
   		p3
   	p22
   p13
f
third line
"""

print PegContext(s).Match(document)
#print PegDebugContext(s).Match(document)