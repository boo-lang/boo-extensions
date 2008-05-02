namespace Boojay.Compilation

import Boo.Lang.Compiler.Steps

class InitializeJavaTypeSystem(AbstractCompilerStep):
	override def Run():
		_context.TypeSystemServices = JavaTypeSystem(_context)
