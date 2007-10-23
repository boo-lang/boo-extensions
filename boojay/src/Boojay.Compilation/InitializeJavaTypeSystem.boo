namespace Boojay.Compilation

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.Steps

class InitializeJavaTypeSystem(AbstractCompilerStep):
	override def Run():
		_context.TypeSystemServices = JavaTypeSystem(_context)
