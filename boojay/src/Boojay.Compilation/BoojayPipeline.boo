namespace Boojay.Compilation

import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.Pipelines

class BoojayPipeline(Compile):
	
	def constructor():
		InsertAfter(NormalizeTypeAndMemberDefinitions, BoojayPreNormalizer())
		Replace(IntroduceGlobalNamespaces, IntroduceBoojayNamespaces())
		Replace(InitializeTypeSystemServices, InitializeJavaTypeSystem())
		Add(BoojayNormalizer())
		Add(BoojayEmitter())
