namespace Boo.OMeta.Parser.Tests

import NUnit.Framework
import Boo.OMeta
import Boo.OMeta.Parser


[TestFixture]
class WhitespaceSensitiveTokenizerTest:
	
	[Test] def IndentDedent():
		code = """
level 1.1:
	level 2.1
	
	level 2.2
	
	
level 1.2

level 1.3:

	level 2.3
	level 2.4:
		level 3.1
"""
		
		expected = [
			Token('eol', 'eol'), 
			Token('line', 'level 1.1:'), 
			Token('indent', 'indent'), 
			Token('line', 'level 2.1'), 
			Token('eol', 'eol'), 
			Token('line', 'level 2.2'), 
			Token('eol', 'eol'), 
			Token('dedent', 'dedent'), 
			Token('line', 'level 1.2'), 
			Token('eol', 'eol'), 
			Token('line', 'level 1.3:'), 
			Token('indent', 'indent'), 
			Token('line', 'level 2.3'), 
			Token('eol', 'eol'), 
			Token('line', 'level 2.4:'), 
			Token('indent', 'indent'), 
			Token('line', 'level 3.1'), 
			Token('eol', 'eol'), 
			Token('dedent', 'dedent'), 
			Token('dedent', 'dedent'), 
		]
		
		tokenizer = WhitespaceSensitiveTokenizer()
		Assert.AreEqual(expected, [item for item in scan(tokenizer, 'scanner', code)])
#		for t as Token in scan(tokenizer, 'scanner', code):
#			print "Token('${t.kind}', '${t.value}'), "
		