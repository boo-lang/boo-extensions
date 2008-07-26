namespace speed

import Boo.OMeta
import Boo.PatternMatching

ometa WordCollector:
	parse = ++(word | number)
	word = (letter >> prefix, ++(letter | digit) >> suffix, wordbreak) ^ "${prefix}${join(suffix, '')}"
	wordbreak = ++whitespace
	number = (++digit >> n, wordbreak) ^ join(n, '')

words = join(("word${i}\n" if 0 == i % 2 else "42\n") for i in range(100000))
start = date.Now
match WordCollector().parse(StringInput(words)):
	case SuccessfulMatch(Input):
		assert Input.IsEmpty
print date.Now - start
