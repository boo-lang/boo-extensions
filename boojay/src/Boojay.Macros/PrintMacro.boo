namespace Boojay.Macros

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro print:
	
	if 0 == len(print.Arguments):
		yield [| java.lang.System.out.println("") |]
		return
		
	last = print.Arguments[-1]
	for arg in print.Arguments:
		if arg is last: break
		yield [| java.lang.System.out.print($arg) |]
		yield [| java.lang.System.out.print(' ') |]
		
	yield [| java.lang.System.out.println($last) |]