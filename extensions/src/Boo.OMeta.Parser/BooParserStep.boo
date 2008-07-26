namespace Boo.OMeta.Parser

import Boo.OMeta
import Boo.PatternMatching
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps

class BooParserStep(AbstractCompilerStep):
	override def Run():
		for input in Parameters.Input:
			using reader=input.Open():
				m = parseModule(reader.ReadToEnd())
				m.Name = input.Name
				CompileUnit.Modules.Add(m)
				
	def parseModule(code as string) as Module:
		
		input = OMetaInput.For(code)
		parser = BooParser()
		
		grammar = extendGrammar(parser)
		
		match grammar.Apply(grammar, 'module', input):
			case SuccessfulMatch(Input: OMetaInput(IsEmpty: true), Value):
				return Value
				
	def extendGrammar(grammar as OMetaGrammar):
		for r in Parameters.References:
			for attribute as SyntaxExtensionAttribute in r.GetCustomAttributes(SyntaxExtensionAttribute, true):
				grammar = attribute.Type(grammar)
		return grammar
		
		