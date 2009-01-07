namespace Boojay.Compilation.BoojayPipelines

import Boojay.Compilation
import Boo.Lang.Compiler.Steps

class BoojayCompilation(Boo.Lang.Compiler.Pipelines.Compile):
	
	def constructor():
		InsertAfter(NormalizeTypeAndMemberDefinitions, BoojayPreNormalizer())
		Replace(IntroduceGlobalNamespaces, IntroduceBoojayNamespaces())
		Replace(InitializeTypeSystemServices, InitializeJavaTypeSystem())
		InsertBefore(NormalizeIterationStatements, NormalizeIterations())
		Add(BoojayNormalizer())
		

class ProduceBytecode(BoojayCompilation):
	
	def constructor():
		Add(BoojayEmitter())
		
class ProduceBoo(BoojayCompilation):
	
	def constructor():
		Add(PrintBoo())	