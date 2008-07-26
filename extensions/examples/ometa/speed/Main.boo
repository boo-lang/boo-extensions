namespace speed

import Boo.OMeta
import Boo.PatternMatching
import Boo.Pegs

ometa WordCollector:
	parse = ++(numbered | word)
	numbered = ((++letter >> letters, ++digit >> digits), wordbreak) ^ (j(letters) + j(digits))
	word = (++letter >> suffix, wordbreak) ^ j(suffix)
	wordbreak = ++whitespace
	number = (++digit >> n, wordbreak) ^ j(n)
	
def j(items):
	return join(items, '')
	
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
	
	ometa = time("ometa"):
		input = OMetaInput.For(words)
		match WordCollector().parse(input):
			case SuccessfulMatch(Input, Value):
				assert Input.IsEmpty
				if printValues: print Value
				
	print "================= FACTOR(${len(words)}):", ometa.TotalMilliseconds / peg.TotalMilliseconds
				
for i in (10, 100, 1000, 10000, 50000, 100000):
	benchmark i, false