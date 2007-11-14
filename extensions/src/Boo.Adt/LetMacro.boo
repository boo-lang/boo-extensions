namespace Boo.Adt

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.PatternMatching

class LetMacro(AbstractAstMacro):
	override def Expand(node as MacroStatement):
		match node.Arguments[0]:
			case BinaryExpression(
					Operator: BinaryOperatorType.Assign,
					Left: ReferenceExpression(Name: name),
					Right: r):
				field = [|
					public static final $name = $r
				|]
				enclosingModule(node).Members.Add(field)