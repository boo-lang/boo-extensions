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
	
[TestFixture]
class OMetaMacroTest:
	
	[Test]
	def Test():
		
		e = E()
		match e.exp(StringInput("11+31")):
			case SuccessfulMatch(Value, Input):
				assert Input.IsEmpty
				assert Value == [['1', '1'], '+', ['3', '1']]