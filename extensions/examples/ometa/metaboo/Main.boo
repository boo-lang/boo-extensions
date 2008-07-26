namespace metaboo

import Boo.OMeta
import Boo.PatternMatching
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.OMeta.Parser

def printTokens(text as string):
	printTokens BooParser(), text
	
def printTokens(grammar as OMetaGrammar, text as string):
	sep = "=" * 20
	print sep
	for token in scan(grammar, 'scanner', text):
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
#print BooParser().module(code)


code = """def foo():
	a = 3
	return bar(a)
"""
#printTokens code
match BooParser().method(code):
	case SuccessfulMatch(Input: OMetaInput(IsEmpty: true), Value: m=Method()):
		print m.ToCodeString()
		
code = """
class Foo:
def foo():
a = 3
return a
end
end
"""
#printTokens WSABooParser(), code
match WSABooParser().Apply('module', code):
	case SuccessfulMatch(Value: mod=Module()):
		print mod.ToCodeString()
	case FailedMatch(Input):
		print Input, Input.Tail

