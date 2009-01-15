namespace Boojay.Compilation.BoojayPipelines

import Boojay.Compilation.Steps
import Boo.Lang.Compiler.Steps

class BoojayCompilation(Boo.Lang.Compiler.Pipelines.Compile):
	
	def constructor():
		Insert(0, InitializeEntityNameMatcher())
		InsertAfter(NormalizeTypeAndMemberDefinitions, NormalizeLiterals())
		Replace(IntroduceGlobalNamespaces, IntroduceBoojayNamespaces())
		Replace(InitializeTypeSystemServices, InitializeJavaTypeSystem())
		InsertBefore(NormalizeIterationStatements, NormalizeIterations())
		Add(NormalizeCallables())
		Add(PatchCallableConstruction())
		Add(InjectCasts())

class ProduceBytecode(BoojayCompilation):
	
	def constructor():
		Add(BoojayEmitter())
		
class ProduceBoo(BoojayCompilation):
	
	def constructor():
		Add(PrintBoo())	