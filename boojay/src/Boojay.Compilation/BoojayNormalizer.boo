namespace Boojay.Compilation

import Boo.Lang.Compiler.Steps

class BoojayNormalizer(AbstractTransformerCompilerStep):
	
	override def Run():
		Visit CompileUnit
		