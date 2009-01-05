namespace Boojay.Macros

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

macro assert:
	
	condition, = assert.Arguments
	yield [| raise java.lang.IllegalStateException($(condition.ToCodeString())) if not $condition |]