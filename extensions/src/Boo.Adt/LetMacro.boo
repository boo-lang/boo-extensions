namespace Boo.Adt

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.PatternMatching

macro let:
"""
Declares a public static final field in the current module.

Usage:

	let answer = 42
"""
	
	assert 1 == len(let.Arguments)
	assert 0 == len(let.Block.Statements)
	
	match let.Arguments[0]:
		case BinaryExpression(
				Operator: BinaryOperatorType.Assign,
				Left: ReferenceExpression(Name: name),
				Right: r):
			field = [|
				public static final $name = $r
			|]
			enclosingModule(let).Members.Add(field)