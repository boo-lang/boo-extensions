namespace miniboo

import Boo.Pegs
import Boo.Lang.Compiler
import Boo.Lang.Compiler.MetaProgramming

//class BooPegContext(PegDebugContext):
class BooPegContext(PegContext):
	
	[getter(Stack)]
	_stack = []
	
	def constructor(text as string):
		super(text)

def push(ctx as BooPegContext):
	push(ctx, text(ctx))

def push(ctx as BooPegContext, value):
	ctx.Stack.Push(value)

def pop(ctx as BooPegContext):
	return ctx.Stack.Pop()
	
def peek(ctx as BooPegContext):
	return ctx.Stack[-1]
	
def currentType(ctx as BooPegContext):
	return peek(ctx) as Ast.TypeDefinition
	
def currentBlock(ctx as BooPegContext):
	return peek(ctx) as Ast.Block
	
keywords = "class", "def", "end"

IsNotKeyword = FunctionExpression() do (ctx as PegContext):
	identifier = text(ctx)
	return identifier not in keywords

peg miniboo:
	Module = EnterModule, AnySpace, ++Member, EndOfFile
	Class = CLASS, Identifier, EnterClass, ClassBody, LeaveClass
	ClassBody = Begin, Space, Member, --(@Space, Member), End
	Member = [Class, Method]
	Method = DEF, Identifier, EnterMethod, LPAREN, RPAREN, Block, LeaveMethod
	Block = Begin, Space, Statement, --(@Space, Statement), End
	Eol = ~NEWLINE
	Statement = ExpressionStatement, NEWLINE
	ExpressionStatement = Invocation, OnExpressionStatement
	Invocation = Expression, EnterInvocation, Argument
	Argument = Expression, OnArgument	
	Expression = [Reference, String]
	Reference = Identifier, OnReference
	String = "'", ++(not "'", any()), "'", { $push(Ast.StringLiteralExpression(Value: $text[1:-1])) }, OptSpace
	Identifier = ++[a-z, A-Z], IsNotKeyword, { $push }, OptSpace
	Begin = ":", OptSpace, Eol
	End = --(OptSpace, NEWLINE)
	OptSpace = ~Space
	Space = ++[' ', '\t']
	AnySpace = --whitespace()
	CLASS = "class", Space
	DEF = "def", Space
	LPAREN = "(", AnySpace
	RPAREN = ")", AnySpace
	NEWLINE = ++"\n"
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
	
	def run():
		print 'Hello, world!'
		
def baz():
	print 'Hello, again'
"""
ctx = BooPegContext(code)
assert ctx.Match(Module),  "Error at " + ctx.Input.Position

module as Ast.Module = pop(ctx)
module.Name = "code"

print module.ToCodeString()

foo as duck = compile(module).GetType("Foo")()
foo.run()