namespace metaboo

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
		id = ((letter | '_') >> prefix, ++(letter | digit | '_') >> suffix) ^ (prefix.ToString() + join(suffix, ''))
		colon = ":"
		kw = (keywords >> value, ~(letter | digit)) ^ value 
	
	keywords = "class" | "pass"
	
	keyword[expected] = ((token["kw"] >> t) and (expected == tokenValue(t))) ^ t
		
	token[expected] = (scanner >> t and tokenMatches(t, expected)) ^ t
	
	scanner = (
		(
		(((indentation >> i) and sameIndent(i), tokens >> t) ^ t)
		| (((indentation >> i) and largerIndent(i)) ^ makeToken("indent"))
		| (((indentation >> i) and smallerIndent(i)) ^ makeToken("dedent"))
		| ((--whitespace, tokens >> t) ^ t)
		| (((--whitespace, ~_) and bufferedDedent()) ^ makeToken("dedent"))
		) >> value
	) ^ value
	
	indentation = (emptyLines, ++(' ' | '\t') >> value, ~whitespace) ^ value
	emptyLines = ++(~~emptyLine, emptyLine)
	emptyLine = spaces, newline
	
	spaces = --(' ' | '\t')
	
	classDef = keyword["class"], token["id"], token["colon"], token["indent"], classBody, token["dedent"]
	
	classBody = (keyword["pass"], eos) | classDef
	
	eos = newline | ~_
	
	newline = '\n' | "\r\n" | "\r"
	
	assign = lvalue, token["eq"], rvalue
	
	lvalue = token["id"]
	
	rvalue = token["num"] | token["id"]
	
	def trace(input as OMetaInput, value):
#		print "trace:", value, stack
		return SuccessfulMatch(input, value)
	
	def sameIndent(i):
#		print "sameIndent", stack, len(i)
		return currentIndent() == len(i)
		
	def largerIndent(i):
		if len(i) > currentIndent():
#			print "largerIndent", stack
			stack.Push(len(i))
			return true
		
	def smallerIndent(i):
		if len(i) < currentIndent():
			stack.Pop()
#			print "smallerIndent", stack
			return true
			
	def bufferedDedent():
#		print "bufferedDedent: ", stack
		if len(stack) > 1:
			stack.Pop()
			return true
		
	def currentIndent() as int:
		return stack[0]
	
	def makeToken(kind):
		return Token(kind, kind)
		
	def makeToken(kind, value):
		return Token(kind, join(value, ''))
		
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
				assert Input.IsEmpty
				break
				
#print Tokenizer().indentation(" \n  foo")
	
code = """
class class0:

	class Bar:
		pass
"""
for token in scan(code):
	print token

print Tokenizer().classDef(code)

