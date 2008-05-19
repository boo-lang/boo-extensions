namespace Boojay.Macros

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro print:
	assert 1 == len(print.Arguments)
	arg, = print.Arguments
	return ExpressionStatement(print.LexicalInfo, [| java.lang.System.out.println($arg) |])