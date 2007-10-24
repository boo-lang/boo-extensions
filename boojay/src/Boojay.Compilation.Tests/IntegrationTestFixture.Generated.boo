
namespace Boojay.Compilation.Tests

import NUnit.Framework

partial class IntegrationTestFixture:

	[Test]
	def Bool_1():
		runTestCase("../boojay/tests/integration/Bool-1.boo")
		
	[Test]
	def Classes_1():
		runTestCase("../boojay/tests/integration/Classes-1.boo")
		
	[Test]
	def HelloWorld():
		runTestCase("../boojay/tests/integration/HelloWorld.boo")
		
	[Test]
	def If_Bool_1():
		runTestCase("../boojay/tests/integration/If-Bool-1.boo")
		
	[Test]
	def If_Not_Bool_1():
		runTestCase("../boojay/tests/integration/If-Not-Bool-1.boo")
		
	[Test]
	def Integers_1():
		runTestCase("../boojay/tests/integration/Integers-1.boo")
		
	[Test]
	def Locals_1():
		runTestCase("../boojay/tests/integration/Locals-1.boo")
		
	[Test]
	def Locals_2():
		runTestCase("../boojay/tests/integration/Locals-2.boo")
		
	[Test]
	def ModuleFunction_1():
		runTestCase("../boojay/tests/integration/ModuleFunction-1.boo")
		
	[Test]
	def ModuleFunction_2():
		runTestCase("../boojay/tests/integration/ModuleFunction-2.boo")
		
	[Test]
	def Objects_1():
		runTestCase("../boojay/tests/integration/Objects-1.boo")
		
	[Test]
	def Objects_2():
		runTestCase("../boojay/tests/integration/Objects-2.boo")
		
	[Test]
	def ReturnValue_1():
		runTestCase("../boojay/tests/integration/ReturnValue-1.boo")
		
	[Test]
	def ReturnValue_2():
		runTestCase("../boojay/tests/integration/ReturnValue-2.boo")
		
	[Test]
	def While_Bool_1():
		runTestCase("../boojay/tests/integration/While-Bool-1.boo")
		
	[Test]
	def While_Not_Bool_1():
		runTestCase("../boojay/tests/integration/While-Not-Bool-1.boo")
		