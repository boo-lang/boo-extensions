namespace Boojay.Compilation.Steps.Macros

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro watch:
	node = watch.Arguments[0]
	for arg in watch.Arguments:
		label = arg.ToCodeString()
		yield [| debugWarningFor $node, $label, "=", $arg |]
		
def debugWarningFor(node as Node, *args):
	warning = CompilerWarningFactory.CustomWarning(node, join(args))
	CompilerContext.Current.Warnings.Add(warning)
