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
l = [1, 2, 3]
assert( 1 == l[0] )
assert( 2 == l[1] )
assert( [1, 2] == l[:2] )
assert( [1] == l[0:1] )
assert( [1] == l[:1] )
assert( 3 == l[-1] )
assert( [2, 3] == l[1:] )
assert( [3, 2, 1] == l[::-1] )
assert( [1, 2, 3] == l[:] )
assert( [1, 3] == l[::2] )
a = not b is not null
b = not c not in (1, 2, 3)
c = not a and b or c and not d
d = not i+j > 5 and h+l < 3
e = not len([1]) == 0
f = not a and len([1]) == 0
a.b.c()[3]().foo()
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

