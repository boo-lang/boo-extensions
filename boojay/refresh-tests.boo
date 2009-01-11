"""
Finds all test cases under tests/integration and generates runTestCase calls
in IntegrationTest.Generated.boo
"""
import System.IO

def testCaseName(fname as string):
	return Path.GetFileNameWithoutExtension(fname).Replace("-", "_")
	
def writeTestCases(writer as TextWriter, baseDir as string):
	count = 0
	for fname in Directory.GetFiles(baseDir):
		continue unless fname.EndsWith(".boo")
		++count		
		writeTestCase(writer, fname)
	for subDir in Directory.GetDirectories(baseDir):
		writeTestCases(writer, subDir)
	print("${count} test cases found in ${baseDir}.")
	
def writeTestCase(writer as TextWriter, fname as string):
	writer.Write("""
	[Test]
	def ${testCaseName(fname)}():
		runTestCase("../boojay/${fname.Replace('\\', '/')}")
		""")
		
using writer = StreamWriter("src/Boojay.Compilation.Tests/IntegrationTest.Generated.boo"):
	writer.Write("""
namespace Boojay.Compilation.Tests

import NUnit.Framework

partial class IntegrationTest:
""")

	writeTestCases(writer, "tests/integration") 
