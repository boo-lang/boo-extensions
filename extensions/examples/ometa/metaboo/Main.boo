namespace metaboo

import System.Text
import Boo.OMeta
import Boo.PatternMatching
import Boo.Adt
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

/*
Before the first line of the file is read, a single zero
is pushed on the stack; this will never be popped off again.
The numbers pushed on the stack will always be strictly
increasing from bottom to top. At the beginning of each
logical line, the line's indentation level is compared
to the top of the stack.

If it is equal, nothing happens. If it is larger,
it is pushed on the stack, and one INDENT token is generated.
If it is smaller, it must be one of the numbers occurring
on the stack; all numbers on the stack that are larger
are popped off, and for each number popped off
a DEDENT token is generated.

At the end of the file, a DEDENT token is generated
for each number remaining on the stack that is
larger than zero. 

http://docs.python.org/ref/indentation.html
*/

data Token(kind as string, value as string)

macro tokens:
	block as Block = tokens.ParentNode
	
	rules = []
	for stmt in tokens.Block.Statements:
		match stmt:
			case ExpressionStatement(Expression: [| $name = $pattern |]):
				e = [| $name = $pattern >> value ^ makeToken($(name.ToString()), value) |]
				e.LexicalInfo = stmt.LexicalInfo
				block.Add(e)
				rules.Add(name)
	
	rule as Expression = rules[0]
	for name as Expression in rules[1:]:
		rule = [| $name | $rule |]
	block.Add([| tokens = $rule |])
	
let stack = [0]
	
ometa Tokenizer:
	
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
		
	token[expected] = (scanner >> t and tokenMatches(t, expected)) ^ t
	
	scanner = (
		(
			  (((_ >> t) and (t isa Token)) ^ t) // token introduced by processDedent
			| (((indentation >> i) and sameIndent(i)) ^ makeToken("eol"))
			| (((indentation >> i) and largerIndent(i)) ^ makeToken("indent"))
			| (((indentation >> i) and smallerIndent(i), $(processDedent(input, i)) >> value) ^ value)
			| ((--whitespace, tokens >> t) ^ t)
		) >> value
	) ^ value
	
	indentation = (emptyLines, spaces >> value, ~whitespace) ^ value
	emptyLines = ++(~~emptyLine, emptyLine)
	emptyLine = spaces, newline
	
	spaces = --space
	
	space = ' ' | '\t'
	
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
	
	newline = '\n' | "\r\n" | "\r"
	
	assign = lvalue, token["eq"], rvalue
	
	lvalue = token["id"]
	
	rvalue = token["num"] | token["id"]
	
	def trace(input as OMetaInput, value):
		print "trace:", value, stack
		return SuccessfulMatch(input, value)
	
	def sameIndent(i):
		return currentIndent() == len(i)
		
	def largerIndent(i):
		if len(i) > currentIndent():
			stack.Push(len(i))
			return true
			
	def processDedent(input as OMetaInput, i):
		while smallerIndent(i):
			input = OMetaInput.ForArgument(makeToken("dedent"), input)
			stack.Pop()
		assert sameIndent(i)
		return SuccessfulMatch(input, makeToken("eol"))
		
	def smallerIndent(i):
		return len(i) < currentIndent()

	def currentIndent() as int:
		return stack[-1]
	
	def makeToken(kind):
		return Token(kind, kind)
		
	def makeToken(kind, value):
		return Token(kind, flatString(value))
		
	def flatString(value) as string:
		if value isa string: return value
		buffer = StringBuilder()
		flatString buffer, value
		return buffer.ToString()
		
	def flatString(buffer as StringBuilder, value):
		match value:
			case string():
				buffer.Append(value)
			case char():
				buffer.Append(value)
			otherwise:
				for item in value:
					flatString buffer, item
		
	def tokenMatches(token as Token, expected):
		return expected is token.kind
		
	def tokenValue(token as Token):
		return token.value
		
def scan(text as string):
	t = Tokenizer()
	input = OMetaInput.For(text)
	while true:
		match t.scanner(input):
			case SuccessfulMatch(Input, Value):
				input = Input
				yield Value
			case FailedMatch(Input):
				#assert Input.IsEmpty, Input.ToString()
				print Input
				break
				
def printTokens(text as string):
	sep = "=" * 20
	print sep
	for token in scan(text):
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

assert stack == [0]

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
printTokens code
print Tokenizer().module(code)


code = """def foo():
	a = 3
"""
printTokens code
print Tokenizer().method(code)

