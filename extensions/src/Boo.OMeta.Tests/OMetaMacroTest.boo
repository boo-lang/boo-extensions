namespace Boo.OMeta.Tests

import Boo.OMeta
import Boo.PatternMatching

import NUnit.Framework

ometa E:
	option ParseTree
	
	dig = '1' | '2' | '3'
	num = ++dig
	exp = (fac, '+', fac) | fac
	fac = (atom, '*', atom) | atom
	atom = num | ('(', exp, ')')
  
[TestFixture]
class OMetaMacroTest:
	
	[Test]
	def InputVariableIsAvailableToUserCode():
		ometa InputTest:
			foo = _ ^ (input.Position)
			bar = $(any(input)) and (input.Position == 1)
			
		tail = OMetaInput.For("01").Tail
		assertMatch 1, InputTest().foo(tail)
		assertMatch char('1'), InputTest().bar(tail)
	
	[Test]
	def TestRulesReturnLastValue():
		ometa G3:
			repetition = ++digit
			sequence = digit, letter
			negation = ~digit
			choice = digit | letter
			repetitionOfSequence = ++(digit, letter) >> ds ^ ds
			
		assertRule G3(), 'repetition', "1234", char('4')
		assertRule G3(), 'sequence', "1a", char('a')
		assertRule G3(), 'choice', "3", char('3')
		assertRule G3(), 'choice', "a", char('a')
		assertRule G3(), 'repetitionOfSequence', "1a2b", [char('a'), char('b')]
		
		match G3().negation("a"):
			case SuccessfulMatch(Input: OMetaInput(Head: char('a')), Value: null):
				pass
		
	[Test]
	def TestUntypedGrammarArgument():
		ometa G1(value):
			parse = ++digit ^ value
			
		assertMatch 42, G1(42).parse("1234")
				
	[Test]
	def TestTypedGrammarArgument():
		ometa G2(value as int):
			parse = ++digit ^ value * 2
			
		assertMatch 42, G2(21).parse("1234")
				
	[Test]
	def TestGrammarConst():
		ometa G4(answer = 42):
			parse = ++digit ^ answer
			
		assertMatch 42, G4().parse("1234")
				
	[Test]
	def TestRepetition():
		ometa Repetition:
			
			option ParseTree
			
			zero_or_many = --letter
			one_or_many = ++letter
		
		r = Repetition()
		match r.zero_or_many("3"):
			case SuccessfulMatch(Input: OMetaInput(Head: char('3'))):
				pass
				
		match r.zero_or_many("abc4"):
			case SuccessfulMatch(Input: OMetaInput(Head: char('4')), Value):
				Assert.AreEqual([char('a'), char('b'), char('c')], Value)
				
		match r.one_or_many("3"):
			case FailedMatch(Input: OMetaInput(Head: char('3'))):
				pass
				
		match r.one_or_many("ab4"):
			case SuccessfulMatch(Input: OMetaInput(Head: char('4')), Value):
				Assert.AreEqual([char('a'), char('b')], Value)
	
	[Test]
	def TestSemanticPredicate():
		
		ometa Numbers:
			odd = num >> n and isOdd(n)
			num = ++digit >> ds ^ int.Parse(join(ds, ''))
			def isOdd(n as int):
				return n % 2 != 0
				
		def odd(input as string):
			return Numbers().odd(input)
				
		match odd("35"):
			case SuccessfulMatch(Value: 35, Input: OMetaInput(IsEmpty: true)):
				pass
				
		match odd("42"):
			case FailedMatch():
				pass
				
	[Test]
	def TestRuleArgument():
		ometa Tokens:
			token[t] = --whitespace, $(characters(input, t))
			
		def token(input as string, value as string):
			return Tokens().token(input, value)
				
		match token("   =-", "="):
			case SuccessfulMatch(Input: OMetaInput(Head: char('-'))):
				pass
				
		match token("   <=*", "<="):
			case SuccessfulMatch(Input: OMetaInput(Head: char('*'))):
				pass
				
	[Test]
	def TestParseTree():
		assertE E()
		
	[Test]
	def TestExtensionParseTree():
		ometa XE < E:
			option ParseTree
			fac = division | super /* super tries to delegate to all prototypes */
			division = (atom, '/', atom)
		
		xe = XE()
		assertE xe
		assertRule xe, 'exp', "1+2/3", [['1'], '+', [['2'], '/', ['3']]]
		assertRule xe, 'exp', "1+(2/(3+1))", [['1'], '+', ['(', [['2'], '/', ['(', [['3'], '+', ['1']], ')']], ')']]
		
	[Test]
	def TestNot():
		
		ometa Lines:
			
			option ParseTree
			
			parse = ++((line >> l, (newline | eof)) ^ join(l, ''))
			line = ++(~newline, _)
			newline = "\n" | "\r\n" | "\r"
			eof = ~_
			
		lines = ["foo", "bar", "baz"]
		assertMatch lines, Lines().parse(OMetaInput.For(lines.Join("\n")))
		
	[Test]
	def TestBinding():
		ometa NumberListParser:
			parse = (num >> head, ++((',', num >> value) ^ value) >> tail) ^ ([head] + (tail as List))
			dig = '1' | '2' | '3' | '4' | '5'
			num = ++dig >> value ^ int.Parse(join(value, ''))
			
		parser = NumberListParser()
		assertRule parser, 'parse', "21,42,51", [21, 42, 51]
		
	[Test]
	def TestTypedBinding():
		ometa HexParser:
			parse = "0x", ++(hexdigit | digit) >> ds ^ join(ds, '')
			hexdigit = (_ >> c as char) and (c >= char('a') and c <= char('f'))
			
		match HexParser().parse("0xff"):
			case SuccessfulMatch(Value: "ff"):
				pass
		
	def assertE(grammar as OMetaGrammar):
		assertRule grammar, 'exp', "11+31", [['1', '1'], '+', ['3', '1']]
		assertRule grammar, 'exp', "1+2*3", [['1'], '+', [['2'], '*', ['3']]]
		
	def assertRule(grammar as OMetaGrammar, rule as string, text as string, expected):
		assertMatch expected, grammar.Apply(grammar, rule, OMetaInput.For(text))
		
	def assertMatch(expected, m as OMetaMatch):
		match m:
			case SuccessfulMatch(Value, Input):
				assert Input.IsEmpty, "Unexpected ${Input.Head}"
				Assert.AreEqual(expected, Value)
