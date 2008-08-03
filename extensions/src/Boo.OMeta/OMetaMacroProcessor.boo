namespace Boo.OMeta

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.PatternMatching

class OMetaMacroProcessor:
	
	ometa as MacroStatement
	options = []
	
	def constructor(ometa as MacroStatement):
		self.ometa = ometa
		self.options = ometa["options"] or []
		
	def expandGrammarSetup():
		block = Block()
		
		for e in expressions():
			match e:
				case [| $(ReferenceExpression(Name: name)) = $pattern |]:
					pass
					
				case [| $(ReferenceExpression(Name: name))[$_] = $pattern |]:
					pass
			
			block.Add([| InstallRule($name, $(ReferenceExpression(Name: "${name}_rule"))) |])
		return block
		
	def introduceRuleMethods(type as TypeDefinition):
		for stmt in ometa.Block.Statements:
			match stmt:
				case ExpressionStatement(Expression: [| $(ReferenceExpression(Name: name)) = $pattern |]):
					m0 = [|
						private def $("${name}_rule")(context as OMetaEvaluationContext, input_ as OMetaInput) as OMetaMatch:
							$(OMetaMacroRuleProcessor(name, options).expand(pattern))
					|]
					type.Members.Add(m0)
					m1 = [|
						def $name(input as OMetaInput):
							return Apply($name, input)
					|]
					type.Members.Add(m1)
					m2 = [|
						def $name(input as System.Collections.IEnumerable):
							return Apply($name, OMetaInput.For(input))
					|]
					type.Members.Add(m2)
					
				case ExpressionStatement(Expression: [| $(ReferenceExpression(Name: name))[$arg] = $pattern |]):
					m0 = [|
						private def $("${name}_rule")(context as OMetaEvaluationContext, input_ as OMetaInput) as OMetaMatch:
							$(OMetaMacroRuleProcessor(name, options).expand(pattern, arg))
					|]
					type.Members.Add(m0)
					m1 = [|
						def $name(input as OMetaInput, $arg):
							return Apply($name, OMetaInput.Prepend($arg, input))
					|]
					type.Members.Add(m1)
					m2 = [|
						def $name(input as System.Collections.IEnumerable, $arg):
							return Apply($name, OMetaInput.Prepend($arg, OMetaInput.For(input)))
					|]
					type.Members.Add(m2)
					
				case DeclarationStatement(Declaration: Declaration(Name: name, Type: null), Initializer: block=BlockExpression()):
					m = Method(
							Name: name,
							LexicalInfo: block.LexicalInfo,
							Body: block.Body,
							Parameters: block.Parameters,
							ReturnType: block.ReturnType)
					
					type.Members.Add(m)
		
	def expandType():
		declaration = ometa.Arguments[0]
							
		type = [|
			class $(grammarName(declaration))(OMetaDelegatingGrammar):
				
				def constructor():
					self($(prototypeFor(declaration)))
					
				// for syntax extensions
				def constructor([required] prototype as OMetaGrammar):
					super(prototype)
					$(expandGrammarSetup())
		|]
		
		introduceRuleMethods type
		introduceGrammarParameters type
		
		type.LexicalInfo = ometa.LexicalInfo
		return type
		
	def introduceGrammarParameters(type as TypeDefinition):
		mie = ometa.Arguments[0] as MethodInvocationExpression
		if mie is null: return
		
		for arg in mie.Arguments:
			match arg:
				case r=ReferenceExpression():
					introduceGrammarParameter type, r, null
					
				case [| $paramName as $paramType |]:
					introduceGrammarParameter type, paramName, paramType
					
				case [| $paramName = $value |]:
					introduceGrammarField type, paramName, null, value
					
	def introduceGrammarParameter(type as TypeDefinition, name as ReferenceExpression, paramType as TypeReference):
		introduceGrammarField type, name, paramType, null
		ctor = type.GetConstructor(0)
		ctor.Parameters.Add(ParameterDeclaration(Name: name.Name, Type: paramType))
		ctor.Body.Add([| self.$name = $name |])
		
	def introduceGrammarField(type as TypeDefinition, name as ReferenceExpression, fieldType as TypeReference, initializer as Expression):
		type.Members.Add(Field(Name: name.Name, Type: fieldType, Initializer: initializer))
			
	def expressions():
		for stmt in ometa.Block.Statements:
			match stmt:
				case ExpressionStatement(Expression: e):
					yield e
				otherwise:
					pass
	
def prototypeFor(e as Expression) as MethodInvocationExpression:
	match e:
		case [| $_ < $prototype |]:
			return [| $prototype() |]
		otherwise:
			return [| OMetaGrammarPrototype() |]
	
def grammarName(e as Expression) as string:
	match e:
		case [| $target() |]:
			return grammarName(target)
		case ReferenceExpression(Name: name):
			return name
		case [| $l < $_ |]:
			return grammarName(l)

def uniqueName():
	return ReferenceExpression(Name: "temp${CompilerContext.Current.AllocIndex()}")
