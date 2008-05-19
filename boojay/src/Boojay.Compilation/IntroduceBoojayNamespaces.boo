namespace Boojay.Compilation

import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.TypeSystem

class IntroduceBoojayNamespaces(IntroduceGlobalNamespaces):
	override def Run():
		NameResolutionService.Reset();			
		NameResolutionService.GlobalNamespace = NamespaceDelegator(
										NameResolutionService.GlobalNamespace,
										SafeGetNamespace("Boojay.Macros"))