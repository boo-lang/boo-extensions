namespace Boo.OMeta.Parser

import System.Text
import Boo.OMeta
import Boo.Lang.PatternMatching
import Boo.Adt

data Token(kind as string, value as string)
	
ometa WhitespaceSensitiveTokenizer():
	
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
			| (((indentation >> i) and sameIndent(input, i)) ^ makeToken("eol"))
			| (((indentation >> i) and largerIndent(input, i), $(processIndent(input, i))) >> value ^ value)			
			| (((indentation >> i) and smallerIndent(input, i), $(processDedent(input, i)) >> value) ^ value)
			| ((--space, tokens >> t) ^ t)
		) >> value
	) ^ value
	
	indentation = empty_lines, spaces
	empty_lines = ~~empty_line, ++empty_line
	empty_line = spaces, newline
	spaces = --space >> value ^ value
	space = ' ' | '\t' | (newline and inWSA(input))
	newline = '\n' | "\r\n" | "\r"
	token[expected] = (scanner >> t and tokenMatches(t, expected)) ^ t
	
	wsa = ~~_ and inWSA(input)
	
	tokens = ++(~newline, _) >> t ^ makeToken("line", t)
	
	enterWhitespaceAgnosticRegion = $(enterWSA(input))
	
	leaveWhitespaceAgnosticRegion = $(leaveWSA(input))
	
	INDENT = token["indent"]
	DEDENT = token["dedent"] | ~_
	EOL = token["eol"]
	
	def inWSA(input as OMetaInput):
		return wsaLevel(input) > 0
		
	def wsaLevel(input as OMetaInput) as int:
		return input.GetMemo("wsaLevel") or 0
		
	def wsaLevel(input as OMetaInput, value as int):
		return success(input.SetMemo("wsaLevel", value))
	
	def enterWSA(input as OMetaInput):
		return wsaLevel(input, wsaLevel(input) + 1)
		
	def leaveWSA(input as OMetaInput):
		return wsaLevel(input, wsaLevel(input) - 1)

	def success(input as OMetaInput):
		return SuccessfulMatch(input, null)

	def indentStack(input as OMetaInput) as List:
		return input.GetMemo("indentStack") or [0]

	def setIndentStack(input as OMetaInput, value as List):
		return input.SetMemo("indentStack", value)

	def sameIndent(input as OMetaInput, i):
		return getIndent(input) == len(i)
		
	def largerIndent(input as OMetaInput, i):
		if len(i) > getIndent(input):
			return true
			
	def processDedent(input as OMetaInput, i):
		indent = List(indentStack(input))
		while cast(int, indent[-1]) > len(i):
			indent.Pop()
			input = OMetaInput.Prepend(makeToken("dedent"), input)

		input = setIndentStack(input, indent)		
		assert sameIndent(input, i)
		return SuccessfulMatch(input, makeToken("eol"))

	def indentLevel(input as OMetaInput, indent as int, value as object):
		return SuccessfulMatch(input.SetMemo("indentLevel", indent), value)


	def processIndent(input as OMetaInput, i):
		newStack = List(indentStack(input))
		newStack.Push(len(i))
		return SuccessfulMatch(setIndentStack(input, newStack), makeToken("indent"))

	def smallerIndent(input as OMetaInput, i):
		return len(i) < getIndent(input)

	def getIndent(input as OMetaInput) as int:
		return indentStack(input)[-1]

		
def tokenMatches(token as Token, expected):
	return expected is token.kind
		
def tokenValue(token as Token):
	return null if token is null
	return token.value

def makeToken(kind):
	return Token(kind, kind)
		
def makeToken(kind, value):
	return Token(kind, flatString(value))
	
def makeString(*values):
	buffer = StringBuilder()
	for value in values:
		flatString buffer, value
	return buffer.ToString()

def flatString(value) as string:
	if value isa string: return value
	buffer = StringBuilder()
	flatString buffer, value
	return buffer.ToString()
	
def flatString(buffer as StringBuilder, value):
	match value:
		case null:
			return
		case string():
			buffer.Append(value)
		case char():
			buffer.Append(value)
		otherwise:
			for item in value:
				flatString buffer, item