namespace Boojay.Compilation

import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.Pipelines

class BoojayPipeline(Compile):
	
	def constructor():
		InsertAfter(InitializeTypeSystemServices, BoojaySemantics())
#		Add(BoojayNormalizer())
		Add(BoojayEmitter())
		Replace(InitializeTypeSystemServices, InitializeJavaTypeSystem())
		Replace(IntroduceGlobalNamespaces, IntroduceBoojayNamespaces())
		
