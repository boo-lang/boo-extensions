namespace metaboo

import Boo.OMeta
import Boo.PatternMatching
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.OMeta.Parser

ometa OMetaParser < WhitespaceSensitiveTokenizer:
	
	tokens:
		eq = "="
		num = ++digit
		id = (letter | '_'), --(letter | digit | '_')
		colon = ":"
		lparen = "("
		rparen = ")"
		kw = (keywords >> value, ~(letter | digit)) ^ value
		
	keywords = "class" | "pass" | "def"
	keyword[expected] = ((token["kw"] >> t) and (expected is tokenValue(t))) ^ t
	
	module = (--whitespace, ++classDef >> types) ^ types
	
	classDef = (
		keyword["class"], token["id"] >> className, token["colon"], token["indent"], classBody >> body, token["dedent"]
	) ^ [className, body]
	
	classBody = (keyword["pass"], eol) ^ null | ++classMember
	
	classMember = method | classDef
	
	method = (
		keyword["def"], token["id"], token["lparen"], token["rparen"], token["colon"],
			token["indent"], methodBody, token["dedent"]
	)
	
	methodBody = ++stmt
	
	stmt = (assign >> value, eol) ^ value
	
	eol = ++token["eol"] | ~_	
	assign = lvalue, token["eq"], rvalue
	
	lvalue = token["id"]
	
	rvalue = token["num"] | token["id"]
		

def printTokens(text as string):
	sep = "=" * 20
	print sep
	for token in scan(WhitespaceSensitiveTokenizer(), 'scanner', text):
		print token
	print sep
				
#print Tokenizer().indentation(" \n  foo")
	
printTokens """
class class0:

	class Bar:
		pass
	
	def foo():
		a = 3
		a = 4
"""

code = """
class Foo:
	def foo():
		a = 3
class Bar:
	class Baz:
		pass
	class Gazong:
		pass
"""
#printTokens code
#print OMetaParser().module(code)


code = """def foo():
	a = 3
"""
#printTokens code
#print OMetaParser().method(code)

