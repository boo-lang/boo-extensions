namespace metaboo

import Boo.OMeta
import Boo.PatternMatching
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
	
def test(code as string):
	printTokens code
	try:
		match m=BooParser().module(code):
			case SuccessfulMatch(Value: module=Module(), Input: OMetaInput(IsEmpty: true)):
				print module.ToCodeString()
			otherwise:
				print "FAILED:", m
	except x:
		print x
		
#while true:
#	line = prompt("> ")
#	if string.IsNullOrEmpty(line) or line == "/q": break
#	test line.Trim()
#return
		
code = """
a as int
print a = 2
a.b.c()[3]().foo() if a > 2
a = 2 *3
i = ~2
j = -~i
h = ~i + ~j * 2
"""
test code
return
code = """
d = 1, 2
e = f, a = g = 42, 2
"""
test code
return
tq = '"'*3
code = """
${tq}foo${tq}
class class0:

	class Bar:
		pass
	
	def foo():
		if a = l as object:
			a = -3
		a += 4
		b = a is null
		c = [1, 2]
		b as object = [3, 4]
		d = a + b as List
		if true:
			pass
"""
test code
return
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

