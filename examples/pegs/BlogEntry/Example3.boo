import Boo.Pegs

peg:
	element = '<', tag, '>', content, '</', @tag, '>'
	tag = ++(a-z)
	content = --(element / text)
	text = not "<", any()
	
assert element.Match(PegContext("<foo><bar>Hello</bar></foo>"))
