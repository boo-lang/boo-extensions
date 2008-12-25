namespace Boojay.Compilation

import Boo.Lang.Compiler.Steps

class InitializeJavaTypeSystem(InitializeTypeSystemServices):
	override def CreateTypeSystemServices():
		return JavaTypeSystem(_context)