namespace Boo.OMeta.Parser.Tests

import NUnit.Framework

import Boo.OMeta
import Boo.PatternMatching

ometa Paragraphs:
	
	parse = ++(paragraph | line)
	paragraph = line, ++((indent, line >> l) ^ l)
	line = (~whitespace, ++(~newline, _) >> l, (newline | eof)) ^ join(l, '')
	indent = ++(~newline, whitespace)
	newline = "\r\n" | "\n" | "\r"
	eof = ~_
	
[TestFixture]
class ParagraphsTest:
	
	[Test] def IndentDedent():
		code = """
level 1.1:
	level 2.1
	level 2.2
level 1.2
level 1.3:
	level 2.3
		""".Trim()
		match Paragraphs().parse(OMetaInput.For(code)):
			case SuccessfulMatch(Value, Input):
				assert Input.IsEmpty, Input.ToString()
				expected = [
					["level 1.1:",
						["level 2.1", "level 2.2"]
					],
					"level 1.2",
					["level 1.3:",
						["level 2.3"]
					]
				]
				Assert.AreEqual(expected, Value)
		