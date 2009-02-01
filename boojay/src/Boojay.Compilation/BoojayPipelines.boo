namespace Boojay.Compilation.BoojayPipelines

import Boojay.Compilation.Steps
import Boo.Lang.Compiler.Steps

def PatchBooPipeline(pipeline as Boo.Lang.Compiler.CompilerPipeline):
"""
Patches a boo pipeline to make it work like a boojay one.
"""
	pipeline.Insert(0, InitializeEntityNameMatcher())
	pipeline.InsertAfter(NormalizeTypeAndMemberDefinitions, NormalizeLiterals())
	pipeline.Replace(IntroduceGlobalNamespaces, IntroduceBoojayNamespaces())
	pipeline.Replace(InitializeTypeSystemServices, InitializeJavaTypeSystem())
	pipeline.InsertBefore(NormalizeIterationStatements, NormalizeIterations())

class BoojayCompilation(Boo.Lang.Compiler.Pipelines.Compile):

	def constructor():
		Add(NormalizeCallables())
		Add(PatchCallableConstruction())
		Add(InjectCasts())
		PatchBooPipeline(self)

class ProduceBytecode(BoojayCompilation):
	
	def constructor():
		Add(BoojayEmitter())
		
class ProduceBoo(BoojayCompilation):
	
	def constructor():
		Add(PrintBoo())	