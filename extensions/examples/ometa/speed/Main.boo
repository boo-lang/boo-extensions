namespace speed

import Boo.OMeta
import Boo.PatternMatching
import Boo.Pegs
import System.Text

ometa WordCollector:
	option ParseTree
	parse = ++(numbered | word)
	numbered = ((++letter >> letters, ++digit >> digits), wordbreak) ^ flatString(letters, digits)
	word = (++letter >> suffix, wordbreak) ^ flatString(suffix)
	wordbreak = ++whitespace
	number = (++digit >> n, wordbreak) ^ flatString(n)
	
def flatString(value) as string:
	if value isa string: return value
	buffer = StringBuilder()
	flatString buffer, value
	return buffer.ToString()
	
def flatString(*values) as string:
	buffer = StringBuilder()
	for value in values:
		flatString buffer, value
	return buffer.ToString()
	
def flatString(buffer as StringBuilder, value):
	match value:
		case s=string():
			buffer.Append(s)
		case c=char():
			buffer.Append(c)
		otherwise:
			for item in value:
				flatString buffer, item
	
def pegWords(text as string):
		
	words = []
	append = words.Add
		
	peg:
		parse = ++[numbered, word]
		numbered = ++letter, ++digit, { append($text) }, wordbreak
		word = ++letter, { append($text) }, wordbreak
		letter = a-z
		digit = 0-9
		wordbreak = ++whitespace()
		
	assert parse.Match(PegContext(text))
	return words
	
def time(label as string, block as callable()):
	start = date.Now
	block()	
	elapsed = date.Now - start
	print "${label}: ${elapsed}"
	return elapsed
	
def benchmark(wordCount as int, printValues as bool):
	
	words = join(("word${i}\n" if 0 == i % 2 else "word\n") for i in range(wordCount))
	
	peg = time("peg"):
		wordList = pegWords(words)
		if printValues: print wordList
	
	ometa = time("ometa - full LR"):
		match WordCollector().parse(words):
			case SuccessfulMatch(Input, Value):
				assert Input.IsEmpty
				if printValues: print Value
				
	ometaNoMemoization = time("ometa - no memoization"):
		match NullEvaluationContext(WordCollector()).Eval('parse', OMetaInput.For(words)):
			case SuccessfulMatch(Input, Value):
				assert Input.IsEmpty
				if printValues: print Value
				
	print "================= SIZE(${len(words)}):", ometa.TotalMilliseconds / peg.TotalMilliseconds, ometaNoMemoization.TotalMilliseconds / peg.TotalMilliseconds
				
for i in (10, 100, 200, 1000, 10000, 50000, 100000):
	benchmark i, i < 11
