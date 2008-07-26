namespace Boo.OMeta.Parser

import System.Text
import Boo.OMeta
import Boo.PatternMatching
import Boo.Adt

data Token(kind as string, value as string)
	
ometa WhitespaceSensitiveTokenizer(stack = [0]):
	
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
	
	scanner = (
		(
			  (((_ >> t) and (t isa Token)) ^ t) // token introduced by processDedent
			| (((indentation >> i) and sameIndent(i)) ^ makeToken("eol"))
			| (((indentation >> i) and largerIndent(i)) ^ makeToken("indent"))
			| (((indentation >> i) and smallerIndent(i), $(processDedent(input, i)) >> value) ^ value)
			| ((--whitespace, tokens >> t) ^ t)
		) >> value
	) ^ value
	
	indentation = (emptyLines, --space >> value, ~whitespace) ^ value
	emptyLines = ++(~~emptyLine, emptyLine)
	emptyLine = spaces, newline
	spaces = --space
	space = ' ' | '\t'
	newline = '\n' | "\r\n" | "\r"
	token[expected] = (scanner >> t and tokenMatches(t, expected)) ^ t
	
	tokens = ++(~newline, _) >> t ^ makeToken("line", t)
	
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
		
def tokenMatches(token as Token, expected):
	return expected is token.kind
		
def tokenValue(token as Token):
	return token.value

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