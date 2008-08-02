import System.IO

def testCaseNameFor(fname as string):
	return Path.GetFileNameWithoutExtension(fname).Replace("-", "_")

def writeTestFixture(writer as TextWriter):
	
	write = { o | writer.WriteLine(o) }
	
	write """namespace Boo.OMeta.Parser.Tests
	
import NUnit.Framework

[TestFixture]
partial class BooParserTestFixture:
"""

	for fname as string in Directory.GetFiles("../../boo/tests/testcases/parser/roundtrip"):
		continue unless fname.EndsWith(".boo")
		write """
	[Test]
	def ${testCaseNameFor(fname)}():
		runTestCase("${Path.GetFileName(fname)}")
	"""
		
#writeTestFixture System.Console.Out

using writer=StreamWriter("src/Boo.OMeta.Parser.Tests/BooParserTestFixture.Generated.boo"):
	writeTestFixture writer