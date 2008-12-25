namespace Boojay.Compilation

import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.Pipelines

class BoojayPipeline(Compile):
	
	def constructor():
		InsertAfter(NormalizeTypeAndMemberDefinitions, BoojayPreNormalizer())
		Replace(IntroduceGlobalNamespaces, IntroduceBoojayNamespaces())
		Replace(InitializeTypeSystemServices, InitializeJavaTypeSystem())
		InsertBefore(NormalizeIterationStatements, NormalizeIterations())
		Add(BoojayNormalizer())
		Add(BoojayEmitter())
