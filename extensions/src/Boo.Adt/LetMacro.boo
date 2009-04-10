namespace Boo.Adt

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro let:
"""
Declares a public static final field in the current module.

Usage:

	let answer = 42
"""
	case [| let $(ReferenceExpression(Name: name)) = $r |]:
		yield [|
			public static final $name = $r
		|]