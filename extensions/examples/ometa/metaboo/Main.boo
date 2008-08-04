namespace metaboo

import Boo.OMeta
import Boo.PatternMatching
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.OMeta.Parser
import NUnit.Framework

syntax Units:
	atom = mass | super
	mass = (integer >> value, "kg") ^ [| Mass($(value as Expression), "kg") |]
	
syntax Ranges:
	
	atom = integer_range | super
	integer_range = (integer >> begin as Expression, DOT, DOT, integer >> end as Expression) ^ [| range($begin, $end) |]

class Fixture:
	def run():
		code = """
import metaboo.Units
import metaboo.Ranges

c1 = { print "foo" }
c2 = { item | print item if item is not null }
a = [1, 2, 3].Find() do (item as int):
	return item > 2
		
	
a = 3kg
print(a)
for i \
	in 1..3:
	pass
"""
		
		result = parse(code)
		assert 0 == len(result.Errors), result.Errors.ToString()
	
		expected = [|
			import metaboo.Units
			import metaboo.Ranges
			
			a = Mass(3, "kg")
			print(a)
			for i in range(1, 3):
				pass
		|]
		Assert.AreEqual(1, len(result.CompileUnit.Modules))
		print result.CompileUnit.Modules[0].ToCodeString()
		Assert.AreEqual(expected.ToCodeString(), result.CompileUnit.Modules[0].ToCodeString())
		
	def parse(code as string):
		compiler = BooCompiler()
		compiler.Parameters.References.Add(GetType().Assembly)
		compiler.Parameters.Input.Add(IO.StringInput("code", code))
		compiler.Parameters.Pipeline = CompilerPipeline()
		compiler.Parameters.Pipeline.Add(BooParserStep())
		result = compiler.Run()
		return result
	
Fixture().run()

code = """
class Foo:
def foo():
a = "\$(3 + 2)"
return a if i > 0
end
end
class Customer:
	[Property(Name, Name: "")]
	_fname as string
end

Foo(Name: 'bar')
assert( [1, 3] == l[::2] )
"""
match WSABooParser().Apply('module', code):
	case SuccessfulMatch(Value: mod=Module()):
		print mod.ToCodeString()
	case FailedMatch(Input):
		print Input, Input.Tail

