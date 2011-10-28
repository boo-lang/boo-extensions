namespace Boo.OMeta.Parser

import System.Text
import Boo.OMeta
import Boo.Lang.PatternMatching
//import Boo.Adt

public class Token(object):

	public final kind as string

	public final value as string
	
	public final start as OMetaInput
	
	public final end as OMetaInput

	public override def ToString() as string:
		return "Token($(self.kind), $(self.value))"

	public override def Equals(o as object) as bool:
		if o is null:
			return false
		if self.GetType() is not o.GetType():
			return false
		other as Token = o
		if string.op_Inequality(self.kind, other.kind):
			return false
		if string.op_Inequality(self.value, other.value):
			return false
		return true

	public def constructor(kind as string, value as string):
		super()
		self.kind = kind
		self.value = value

	public def constructor(kind as string, value as string, start as OMetaInput, end as OMetaInput):
		super()
		self.kind = kind
		self.value = value
		self.start = start
		self.end = end


	
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
	
	scanner = ( (((_ >> t) and (t isa Token)) ^ t) // token introduced by processDedent
			| (((indentation >> i) and sameIndent(input, i)) ^ makeToken("eol"))
			| ((indentation >> i) and largerIndent(input, i), $(processIndent(input, i)))
			| ((indentation >> i) and smallerIndent(input, i), $(processDedent(input, i)))
			| ((--space, tokens >> t) ^ t)
	)
	
	indentation = empty_lines, spaces
	empty_lines = ++empty_line
	empty_line = spaces, newline
	spaces = --space >> value ^ value
	space = ' ' | '\t' | (newline and inWSA(input))
	newline = '\n' | "\r\n" | "\r", $(newLine(input))
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
		return success(input, null)

	def success(input as OMetaInput, value):
		return SuccessfulMatch(input, value)

	def indentStack(input as OMetaInput) as List:
		return input.GetMemo("indentStack") or [0]

	def setIndentStack(input as OMetaInput, value as List):
		return input.SetMemo("indentStack", value)

	def sameIndent(input as OMetaInput, i):
		return getIndent(input) == len(i)
		
	def largerIndent(input as OMetaInput, i):
		if len(i) > getIndent(input):
			return true

	def smallerIndent(input as OMetaInput, i):
		return len(i) < getIndent(input)

	def processDedent(input as OMetaInput, i):
		original = input
		indent = List(indentStack(input))
		while cast(int, indent[-1]) > len(i):
			indent.Pop()
			input = OMetaInput.Prepend(makeToken("dedent"), input, original)

		input = setIndentStack(input, indent)		
		assert sameIndent(input, i)
		return SuccessfulMatch(input, makeToken("eol"))

	def indentLevel(input as OMetaInput, indent as int, value as object):
		return SuccessfulMatch(input.SetMemo("indentLevel", indent), value)

	def processIndent(input as OMetaInput, i):
		newStack = List(indentStack(input))
		newStack.Push(len(i))
		return SuccessfulMatch(setIndentStack(input, newStack), makeToken("indent"))

	def getIndent(input as OMetaInput) as int:
		return indentStack(input)[-1]

	def getLine(input as OMetaInput) as int:
		return input.GetMemo("line") or 1
		
	def setLine(input as OMetaInput, value as int):
		return input.SetMemo("line", value)

	def setLineStart(input as OMetaInput, value as int):
		return input.SetMemo("lineStart", value)
	
	def newLine(input as OMetaInput):		
		input = setLineStart(input, input.Position)
		return success(setLine(input, getLine(input) + 1))
	
def setMemoStart(input as OMetaInput, value):
	return SuccessfulMatch(input.SetMemo("start", value), null)

def getMemoStart(input as OMetaInput):
	return input.GetMemo("start")

def getMemoEnd(input as OMetaInput):
	return input.GetMemo("end")
	
def getBack(value):
	return value

def tokenMatches(token as Token, expected):
	return expected is token.kind
		
def tokenValue(token as Token):
	return null if token is null
	return token.value

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
				
def makeToken(kind):
	return Token(kind, kind)
		
def makeToken(kind, value):
	return Token(kind, flatString(value))

def makeToken(kind, value, start, end):
	return Token(kind, flatString(value), start, end)				