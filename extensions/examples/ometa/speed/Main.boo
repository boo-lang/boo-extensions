namespace speed

import Boo.OMeta
import Boo.PatternMatching

ometa WordCollector:
	parse = ++(numbered | word)
	numbered = ((++letter >> letters, ++digit >> digits), wordbreak) ^ (j(letters) + j(digits))
	word = (++letter >> suffix, wordbreak) ^ j(suffix)
	wordbreak = ++whitespace
	number = (++digit >> n, wordbreak) ^ j(n)
	
def j(items):
	return join(items, '')

words = join(("word${i}\n" if 0 == i % 2 else "word\n") for i in range(100000))
start = date.Now
#input = StringInput(words)
input = OMetaInput.For(words)
match WordCollector().parse(input):
	case SuccessfulMatch(Input, Value):
		assert Input.IsEmpty
#		print Value
print date.Now - start
