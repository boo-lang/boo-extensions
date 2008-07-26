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
		
		e = E()
		AssertE e
		
	[Test]
	def TestExtension():
		xe = XE()
		AssertE xe
		AssertRule xe, 'exp', "1+2/3", list(list('1'), '+', list(list('2'), '/', list('3')))
		AssertRule xe, 'exp', "1+(2/(3+1))", list(list('1'), '+', list('(', list(list('2'), '/', list('(', list(list('3'), '+', list('1')), ')')), ')'))
		
	[Test]
	def TestBinding():
		ometa NumberListParser:
			parse = (num >> head, ++((',', num >> value) ^ value) >> tail) ^ OMetaCons(head, tail)
			dig = '1' | '2' | '3' | '4' | '5'
			num = ++dig >> value ^ int.Parse(value.ToString())
			
		parser = NumberListParser()
		AssertRule parser, 'parse', "21,42,51", list(21, 42, 51)
		
	def AssertE(grammar as OMetaGrammar):
		AssertRule grammar, 'exp', "11+31", list(list('1', '1'), '+', list('3', '1'))
		AssertRule grammar, 'exp', "1+2*3", list(list('1'), '+', list(list('2'), '*', list('3')))
		
	def AssertRule(grammar as OMetaGrammar, rule as string, text as string, expected):
		
		match grammar.Apply(grammar, rule, StringInput(text)):
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
	