namespace Boojay.Macros

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro print:
	
	if 0 == len(print.Arguments):
		return ExpressionStatement(print.LexicalInfo, [| java.lang.System.out.println("") |])
		
	b = Block(print.LexicalInfo)
	last = print.Arguments[-1]
	for arg in print.Arguments:
		if arg is last: break
		b.Add([| java.lang.System.out.print($arg) |])
		b.Add([| java.lang.System.out.print(' ') |])
	b.Add([| java.lang.System.out.println($last) |])
	return b