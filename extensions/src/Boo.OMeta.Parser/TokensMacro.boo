namespace Boo.OMeta.Parser

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.PatternMatching

macro tokens:
	block as Block = tokens.ParentNode
	
	rules = []
	for stmt in tokens.Block.Statements:
		match stmt:
			case ExpressionStatement(Expression: [| $name = $pattern |]):
				e = [| $name = $pattern >> value ^ makeToken($(name.ToString()), value) |]
				e.LexicalInfo = stmt.LexicalInfo
				block.Add(e)
				rules.Add(name)
	
	rule as Expression = rules[0]
	for name as Expression in rules[1:]:
		rule = [| $name | $rule |]
	block.Add([| tokens = $rule |])