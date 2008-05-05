namespace miniboo

import Boo.Pegs
import Boo.Lang.Compiler
import Boo.Lang.Compiler.MetaProgramming

def push(ctx as PegContextWithPayload[of List]):
	push(ctx, text(ctx))

def push(ctx as PegContextWithPayload[of List], value):
	ctx.Payload.Push(value)

def pop(ctx as PegContextWithPayload[of List]):
	return ctx.Payload.Pop()
	
def peek(ctx as PegContextWithPayload[of List]):
	return ctx.Payload[-1]
	
def currentType(ctx as PegContextWithPayload[of List]):
	return peek(ctx) as Ast.TypeDefinition
	
def currentBlock(ctx as PegContextWithPayload[of List]):
	return peek(ctx) as Ast.Block
	
keywords = "class", "def", "end"

IsNotKeyword = FunctionExpression() do (ctx as PegContext):
	identifier = text(ctx)
	return identifier not in keywords

peg miniboo:
	Module = EnterModule, OptionalSpacing, ++Member, EndOfFile
	Class = CLASS, Identifier, EnterClass, Begin, ++Member, End, LeaveClass
	Member = [Class, Method]
	Method = DEF, Identifier, EnterMethod, LPAREN, RPAREN, Block, LeaveMethod
	Block = Begin, ++Statement, End
	Statement = ExpressionStatement
	ExpressionStatement = Invocation, OnExpressionStatement
	Invocation = Expression, EnterInvocation, Argument
	Argument = Expression, OnArgument	
	Expression = [Reference, String]
	Reference = Identifier, OnReference
	String = "'", ++(not "'"), "'", { $push(Ast.StringLiteralExpression(Value: $text[1:-1])) }, Spacing
	Identifier = ++[a-z, A-Z], IsNotKeyword, { $push }, OptionalSpacing
	Begin = ":", OptionalSpacing
	End = "end", Spacing
	Spacing = ++[' ', '\t', '\r', '\n']
	OptionalSpacing = ~Spacing
	CLASS = "class", Spacing
	DEF = "def", Spacing
	LPAREN = "(", OptionalSpacing
	RPAREN = ")", OptionalSpacing
	EndOfFile = not any()
	
	# actions
	EnterModule = do:
		$push(Ast.Module())
	
	EnterClass = do:
		type = Ast.ClassDefinition(Name: $pop)
		$currentType.Members.Add(type)
		$push(type)
	
	LeaveClass = do:
		$pop
	
	EnterMethod = do:
		method = Ast.Method(Name: $pop)
		$currentType.Members.Add(method)
		$push(method.Body)
	
	LeaveMethod = do:
		$pop
	
	OnExpressionStatement = do:
		e = $pop
		$currentBlock.Add(Ast.ExpressionStatement(Expression: e))
	
	OnReference = do:
		$push(Ast.ReferenceExpression(Name: $pop))
	
	EnterInvocation = do:
		$push(Ast.MethodInvocationExpression(Target: $pop))
	
	OnArgument = do:
		arg = $pop
		($peek as Ast.MethodInvocationExpression).Arguments.Add(arg)


code = """
class Foo:
	class Nested:
		def bar():
			print 'yahoo'
		end
	end
	def run():
		print 'Hello, world!'
	end
end
"""
ctx = PegContextWithPayload[of List](code, [])
assert ctx.Match(Module),  "Error at " + ctx.Input.Position

module as Ast.Module = pop(ctx)
module.Name = "code"

print module.ToCodeString()

foo as duck = compile(module).GetType("Foo")()
foo.run()