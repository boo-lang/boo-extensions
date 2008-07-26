namespace Boo.OMeta.Tests

import Boo.OMeta
import NUnit.Framework

[TestFixture]
class OMetaInputTest:
	
	[Test]
	def Position():
		
		items = range(10)
		input = OMetaInput.For(items)
		for i in items:
			Assert.AreEqual(i, input.Position)
			input = input.Tail
		assert input.IsEmpty
		
	[Test]
	def TailIsCached():
		
		input = OMetaInput.For(range(3))
		while not input.IsEmpty:
			Assert.AreSame(input.Tail, input.Tail)
			input = input.Tail