namespace Boo.OMeta.Parser.Tests

import Boo.Lang
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
		s = scan(tokenizer, 'scanner', normalize(code))
		Assert.AreEqual(expected, [item for item in s])
	
	
	[Test] 
	def WhitespaceAgnosticRegionsIndentStack():
/*
It tests that indent is correclty calculated for WSA regions for some complex cases.
This test is related to fix for WhitespaceSensitiveTokenizer. The fix changes algorithm calculating indent stack.
Now stack is stored in OMetaInputWithMemo so if rule fails value of stack rolls back. Previously stack never rolled back. It
created issues in the complex WSA rules like one provided below.
*/
		ometa IndentStackTest < WhitespaceSensitiveTokenizer:
			tokens:
				lparen = "("
				rparen = ")"
				id = ((letter | '_') >> p, --(letter | digit | '_') >> s) ^ makeString(p, s)
				dot = "."
				plus = "+"
			
			member_reference = ((member_reference >> a, enterWhitespaceAgnosticRegion, DOT, ID >> b, leaveWhitespaceAgnosticRegion ^ [a,b]) | func) >> x, (PLUS | "") ^ x
			
			func = (ID >> i, LPAREN, RPAREN ^ makeToken("func", tokenValue(i))) | ID
			
			eol = (++EOL | ~_) ^ null
			
			stmt = member_reference >> r, eol ^ r
			stmts = (++stmt) >> r ^ r

		code = """foo()
	.bar
foo()"""
		expected = [[
			[Token('func', 'foo'),Token('id', 'bar')], 
			Token('func', 'foo') 
		]]

		tokenizer = IndentStackTest()
		
		Assert.AreEqual(expected, scan(tokenizer, 'stmts', normalize(code)))	

	[Test] def IndentDedent():
		code = """
level 1.1:
	level 2.1
	
	level 2.2
	
	
level 1.2
	level 2.3
		level 3.1
level 1.3:

	level 2.4
	level 2.5:
		level 3.2
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
			Token('indent', 'indent'), 	
			Token('line', 'level 2.3'),			
			Token('indent', 'indent'), 	
			Token('line', 'level 3.1'), 
			Token('eol', 'eol'), 
			Token('dedent', 'dedent'), 
			Token('dedent', 'dedent'),			
			Token('line', 'level 1.3:'), 
			Token('indent', 'indent'), 
			Token('line', 'level 2.4'), 
			Token('eol', 'eol'), 
			Token('line', 'level 2.5:'), 
			Token('indent', 'indent'), 
			Token('line', 'level 3.2'), 
			Token('eol', 'eol'), 
			Token('dedent', 'dedent'), 
			Token('dedent', 'dedent'), 
		]
		
		tokenizer = WhitespaceSensitiveTokenizer()
		s = scan(tokenizer, 'scanner', code)
		Assert.AreEqual(expected, [item for item in s])
#		for t as Token in scan(tokenizer, 'scanner', code):
#			print "Token('${t.kind}', '${t.value}'), "

	def normalize(s as string):
		return s.Replace("\r\n", "\n")