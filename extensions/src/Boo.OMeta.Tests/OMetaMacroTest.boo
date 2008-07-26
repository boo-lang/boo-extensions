namespace Boo.OMeta.Tests

import Boo.OMeta
import Boo.PatternMatching

import NUnit.Framework

// layout rules can be implemented with a filter that matches whitespace
// and generates Indent/Dedent values

ometa E:
	dig = '1' | '2' | '3'
	num = ++dig
	exp = (fac, '+', fac) | fac
	fac = (atom, '*', atom) | atom
	atom = num | ('(', exp, ')')
   
ometa XE < E:
	fac = division | super /* super tries to delegate to all prototypes */
	division = (atom, '/', atom)

[TestFixture]
class OMetaMacroTest:
	
	[Test]
	def Test():
		AssertE E()
		
	[Test]
	def TestSemanticPredicate():
		
		ometa Numbers:
			odd = num >> n and isOdd(n)
			num = ++digit >> ds ^ int.Parse(join(ds, ''))
			def isOdd(n as int):
				return n % 2 != 0
				
		def odd(input):
			return Numbers().odd(OMetaInput.For(input))
				
		match odd("35"):
			case SuccessfulMatch(Value: 35, Input: OMetaInput(IsEmpty: true)):
				pass
				
		match odd("42"):
			case FailedMatch():
				pass
		
	[Test]
	def TestExtension():
		xe = XE()
		AssertE xe
		AssertRule xe, 'exp', "1+2/3", [['1'], '+', [['2'], '/', ['3']]]
		AssertRule xe, 'exp', "1+(2/(3+1))", [['1'], '+', ['(', [['2'], '/', ['(', [['3'], '+', ['1']], ')']], ')']]
		
	[Test]
	def TestNot():
		
		ometa Lines:
			parse = ++((line >> l, (newline | eof)) ^ join(l, ''))
			line = ++(~newline, _)
			newline = "\n" | "\r\n" | "\r"
			eof = ~_
			
		lines = ["foo", "bar", "baz"]
		AssertMatch lines, Lines().parse(OMetaInput.For(lines.Join("\n")))
		
	[Test]
	def TestBinding():
		ometa NumberListParser:
			parse = (num >> head, ++((',', num >> value) ^ value) >> tail) ^ ([head] + (tail as List))
			dig = '1' | '2' | '3' | '4' | '5'
			num = ++dig >> value ^ int.Parse(join(value, ''))
			
		parser = NumberListParser()
		AssertRule parser, 'parse', "21,42,51", [21, 42, 51]
		
	def AssertE(grammar as OMetaGrammar):
		AssertRule grammar, 'exp', "11+31", [['1', '1'], '+', ['3', '1']]
		AssertRule grammar, 'exp', "1+2*3", [['1'], '+', [['2'], '*', ['3']]]
		
	def AssertRule(grammar as OMetaGrammar, rule as string, text as string, expected):
		AssertMatch expected, grammar.Apply(grammar, rule, OMetaInput.For(text))
		
	def AssertMatch(expected, m as OMetaMatch):
		match m:
			case SuccessfulMatch(Value, Input):
				assert Input.IsEmpty, "Unexpected ${Input.Head}"
				Assert.AreEqual(expected, Value)

#	charRange(begin as char, end as  = character >> c
	// semantic predicates with 'and'
	// even = num >> n and 0 == n % 2
	
#syntax decimal: // switches the global syntax to this one augmented to the global
#	literal = (digits+):numbers 'd' => [| decimal.Parse($(numbers.ToString())) |]
#		| super

#				
#ometa XE < E:
#	E.fac = (num, '/', num) | super /* super tries to delegate to all prototypes */
#	
#interface SaxContentHandler:
#	def startTag(tagName as string)
#	def contents(contents as string)
#	def endTag()
#	
#ometa SaxParser(handler as SaxContentHandler):
#	tag = startTag >> $tagName, contents, endTag($tagName)
#	startTag = lt, identifier >> $tagName, gt
#	contents = ++(~lt, _)
#	endTag(tagName) = lt, token($tagName), token("/>")
#	lt = token("<")
#	gt = token(">")
	