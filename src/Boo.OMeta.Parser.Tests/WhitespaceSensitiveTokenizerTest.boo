namespace Boo.OMeta.Parser.Tests

import NUnit.Framework
import Boo.OMeta
import Boo.OMeta.Parser


[TestFixture]
class WhitespaceSensitiveTokenizerTest:
	
	[Test] def WhitespaceAgnosticRegions():
		ometa ParensForGrouping < WhitespaceSensitiveTokenizer:
			tokens = lparen | rparen | line
			line = ++(~("(" | ")" | (~wsa, newline) ), _) >> value ^ makeToken("line", value)
			lparen = ("(", enterWhitespaceAgnosticRegion) ^ makeToken("lparen")
			rparen = (")", leaveWhitespaceAgnosticRegion) ^ makeToken("rparen")
		
		code = """
level1:
	(foo
		bar)
	baz
level11
"""
		expected = [
			Token('eol', 'eol'), 
			Token('line', 'level1:'), 
			Token('indent', 'indent'), 
			Token('lparen', 'lparen'), 
			Token('line', 'foo\n\t\tbar'), 
			Token('rparen', 'rparen'), 
			Token('eol', 'eol'), 
			Token('line', 'baz'), 
			Token('eol', 'eol'), 
			Token('dedent', 'dedent'), 
			Token('line', 'level11'), 
			Token('eol', 'eol'),
		]
		
		tokenizer = ParensForGrouping()
		Assert.AreEqual(expected, [item for item in scan(tokenizer, 'scanner', normalize(code))])
	
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

	def normalize(s as string):
		return s.Replace("\r\n", "\n")