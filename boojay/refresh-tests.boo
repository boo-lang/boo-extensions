"""
Finds all test cases under tests/integration and generates runTestCase calls
in IntegrationTestFixture.Generated.boo
"""
import System.IO

def testCaseName(fname as string):
	return Path.GetFileNameWithoutExtension(fname).Replace("-", "_")
	
def writeTestCases(writer as TextWriter, baseDir as string):
	count = 0
	for fname in Directory.GetFiles(baseDir):
		continue unless fname.EndsWith(".boo")
		++count		
		writer.Write("""
	[Test]
	def ${testCaseName(fname)}():
		runTestCase("../boojay/${fname.Replace('\\', '/')}")
		""")
	print("${count} test cases found in ${baseDir}.")
	
using writer = StreamWriter("src/Boojay.Compilation.Tests/IntegrationTestFixture.Generated.boo"):
	writer.Write("""
namespace Boojay.Compilation.Tests

import NUnit.Framework

partial class IntegrationTestFixture:
""")

	writeTestCases(writer, "tests/integration") 
