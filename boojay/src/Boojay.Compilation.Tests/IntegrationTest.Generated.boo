
namespace Boojay.Compilation.Tests

import NUnit.Framework

partial class IntegrationTest:

	[Test]
	def BoolArray():
		runTestCase("tests/integration/arrays/BoolArray.boo")
		
	[Test]
	def CharArray():
		runTestCase("tests/integration/arrays/CharArray.boo")
		
	[Test]
	def IntArray():
		runTestCase("tests/integration/arrays/IntArray.boo")
		
	[Test]
	def SimpleStringArray():
		runTestCase("tests/integration/arrays/SimpleStringArray.boo")
		
	[Test]
	def DefaultReturnValues_1():
		runTestCase("tests/integration/assorted/DefaultReturnValues-1.boo")
		
	[Test]
	def HelloWorld():
		runTestCase("tests/integration/assorted/HelloWorld.boo")
		
	[Test]
	def ListLiteral():
		runTestCase("tests/integration/assorted/ListLiteral.boo")
		
	[Test]
	def Locals_1():
		runTestCase("tests/integration/assorted/Locals-1.boo")
		
	[Test]
	def Locals_2():
		runTestCase("tests/integration/assorted/Locals-2.boo")
		
	[Test]
	def Methods_1():
		runTestCase("tests/integration/assorted/Methods-1.boo")
		
	[Test]
	def ModuleFunction_1():
		runTestCase("tests/integration/assorted/ModuleFunction-1.boo")
		
	[Test]
	def ModuleFunction_2():
		runTestCase("tests/integration/assorted/ModuleFunction-2.boo")
		
	[Test]
	def Namespaces():
		runTestCase("tests/integration/assorted/Namespaces.boo")
		
	[Test]
	def ReturnValue_1():
		runTestCase("tests/integration/assorted/ReturnValue-1.boo")
		
	[Test]
	def ReturnValue_2():
		runTestCase("tests/integration/assorted/ReturnValue-2.boo")
		
	[Test]
	def UninitializedVariable():
		runTestCase("tests/integration/assorted/UninitializedVariable.boo")
		
	[Test]
	def AutomaticDowncastingOnInvocation():
		runTestCase("tests/integration/autocasting/AutomaticDowncastingOnInvocation.boo")
		
	[Test]
	def Join_1():
		runTestCase("tests/integration/builtins/Join-1.boo")
		
	[Test]
	def Callables_1():
		runTestCase("tests/integration/callables/Callables-1.boo")
		
	[Test]
	def Callables_2():
		runTestCase("tests/integration/callables/Callables-2.boo")
		
	[Test]
	def Callables_3():
		runTestCase("tests/integration/callables/Callables-3.boo")
		
	[Test]
	def Closures_1():
		runTestCase("tests/integration/callables/Closures-1.boo")
		
	[Test]
	def Coercion_1():
		runTestCase("tests/integration/callables/Coercion-1.boo")
		
	[Test]
	def InstanceMethodReference_1():
		runTestCase("tests/integration/callables/InstanceMethodReference-1.boo")
		
	[Test]
	def PascalCaseAndCamelCase():
		runTestCase("tests/integration/crossplatformability/PascalCaseAndCamelCase.boo")
		
	[Test]
	def And_1():
		runTestCase("tests/integration/expressions/And-1.boo")
		
	[Test]
	def And_2():
		runTestCase("tests/integration/expressions/And-2.boo")
		
	[Test]
	def And_3():
		runTestCase("tests/integration/expressions/And-3.boo")
		
	[Test]
	def Cast_1():
		runTestCase("tests/integration/expressions/Cast-1.boo")
		
	[Test]
	def HashLiterals():
		runTestCase("tests/integration/expressions/HashLiterals.boo")
		
	[Test]
	def Isa_1():
		runTestCase("tests/integration/expressions/Isa-1.boo")
		
	[Test]
	def MultiAssignment():
		runTestCase("tests/integration/expressions/MultiAssignment.boo")
		
	[Test]
	def Or_1():
		runTestCase("tests/integration/expressions/Or-1.boo")
		
	[Test]
	def Or_2():
		runTestCase("tests/integration/expressions/Or-2.boo")
		
	[Test]
	def Or_3():
		runTestCase("tests/integration/expressions/Or-3.boo")
		
	[Test]
	def Or_4():
		runTestCase("tests/integration/expressions/Or-4.boo")
		
	[Test]
	def StringInterpolation():
		runTestCase("tests/integration/expressions/StringInterpolation.boo")
		
	[Test]
	def TryCast_1():
		runTestCase("tests/integration/expressions/TryCast-1.boo")
		
	[Test]
	def GeneratorAsArgumentToMethod():
		runTestCase("tests/integration/generators/GeneratorAsArgumentToMethod.boo")
		
	[Test]
	def GeneratorEnumerator():
		runTestCase("tests/integration/generators/GeneratorEnumerator.boo")
		
	[Test]
	def GeneratorExpressionAsClosure():
		runTestCase("tests/integration/generators/GeneratorExpressionAsClosure.boo")
		
	[Test]
	def GeneratorWithExceptionHandler():
		runTestCase("tests/integration/generators/GeneratorWithExceptionHandler.boo")
		
	[Test]
	def GeneratorWithTryEnsure():
		runTestCase("tests/integration/generators/GeneratorWithTryEnsure.boo")
		
	[Test]
	def IntGenerator():
		runTestCase("tests/integration/generators/IntGenerator.boo")
		
	[Test]
	def IntGeneratorExpression():
		runTestCase("tests/integration/generators/IntGeneratorExpression.boo")
		
	[Test]
	def ListGenerator():
		runTestCase("tests/integration/generators/ListGenerator.boo")
		
	[Test]
	def MultiGeneratorExpression():
		runTestCase("tests/integration/generators/MultiGeneratorExpression.boo")
		
	[Test]
	def MultiGeneratorExpressionWithFilter():
		runTestCase("tests/integration/generators/MultiGeneratorExpressionWithFilter.boo")
		
	[Test]
	def NestedEnsures():
		runTestCase("tests/integration/generators/NestedEnsures.boo")
		
	[Test]
	def Simplest():
		runTestCase("tests/integration/generators/Simplest.boo")
		
	[Test]
	def StringGenerator():
		runTestCase("tests/integration/generators/StringGenerator.boo")
		
	[Test]
	def Assert_1():
		runTestCase("tests/integration/macros/Assert-1.boo")
		
	[Test]
	def Match_1():
		runTestCase("tests/integration/macros/Match-1.boo")
		
	[Test]
	def BeanProperties():
		runTestCase("tests/integration/properties/BeanProperties.boo")
		
	[Test]
	def ForItemInArray():
		runTestCase("tests/integration/statements/ForItemInArray.boo")
		
	[Test]
	def ForItemInIntArray():
		runTestCase("tests/integration/statements/ForItemInIntArray.boo")
		
	[Test]
	def ForItemInIterable():
		runTestCase("tests/integration/statements/ForItemInIterable.boo")
		
	[Test]
	def ForItemInString():
		runTestCase("tests/integration/statements/ForItemInString.boo")
		
	[Test]
	def If_Bool_1():
		runTestCase("tests/integration/statements/If-Bool-1.boo")
		
	[Test]
	def If_Not_Bool_1():
		runTestCase("tests/integration/statements/If-Not-Bool-1.boo")
		
	[Test]
	def ReturnFromVoid():
		runTestCase("tests/integration/statements/ReturnFromVoid.boo")
		
	[Test]
	def Try_1():
		runTestCase("tests/integration/statements/Try-1.boo")
		
	[Test]
	def TryEnsure():
		runTestCase("tests/integration/statements/TryEnsure.boo")
		
	[Test]
	def TryExceptEnsure():
		runTestCase("tests/integration/statements/TryExceptEnsure.boo")
		
	[Test]
	def TryExceptReraise():
		runTestCase("tests/integration/statements/TryExceptReraise.boo")
		
	[Test]
	def TryFailure():
		runTestCase("tests/integration/statements/TryFailure.boo")
		
	[Test]
	def While_Bool_1():
		runTestCase("tests/integration/statements/While-Bool-1.boo")
		
	[Test]
	def While_Not_Bool_1():
		runTestCase("tests/integration/statements/While-Not-Bool-1.boo")
		
	[Test]
	def Bool_1():
		runTestCase("tests/integration/types/Bool-1.boo")
		
	[Test]
	def Classes_1():
		runTestCase("tests/integration/types/Classes-1.boo")
		
	[Test]
	def Constructors_1():
		runTestCase("tests/integration/types/Constructors-1.boo")
		
	[Test]
	def Equals_1():
		runTestCase("tests/integration/types/Equals-1.boo")
		
	[Test]
	def Integers_1():
		runTestCase("tests/integration/types/Integers-1.boo")
		
	[Test]
	def Interfaces_1():
		runTestCase("tests/integration/types/Interfaces-1.boo")
		
	[Test]
	def NotImplemented_1():
		runTestCase("tests/integration/types/NotImplemented-1.boo")
		
	[Test]
	def Objects_1():
		runTestCase("tests/integration/types/Objects-1.boo")
		
	[Test]
	def Objects_2():
		runTestCase("tests/integration/types/Objects-2.boo")
		
	[Test]
	def Overrides_1():
		runTestCase("tests/integration/types/Overrides-1.boo")
		