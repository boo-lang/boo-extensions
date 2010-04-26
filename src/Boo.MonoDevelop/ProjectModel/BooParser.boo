namespace Boo.MonoDevelop.ProjectModel

import System
import System.IO

import MonoDevelop.Projects.Dom
import MonoDevelop.Projects.Dom.Parser

import Boo.Lang.Compiler as BLC

class BooParser(AbstractParser):
	
	def constructor():
		super("Boo", BooMimeType)
		
	override def CanParse(fileName as string):
		return Path.GetExtension(fileName).ToLower() == ".boo"
		
	override def Parse(dom as ProjectDom, fileName as string, content as string):
		
		document = ParsedDocument(fileName)
		document.CompilationUnit = CompilationUnit(fileName)
		
		try:
			result = ParseBooText(fileName, content)
			result.CompileUnit.Accept(DomConversionVisitor(document.CompilationUnit))
			if len(result.Errors): Console.Error.WriteLine(result.Errors.ToString(true))
		except e:
			Console.Error.WriteLine(e)
		
		return document
		
	override def CreateResolver(dom as ProjectDom, editor, fileName as string):
		doc = cast(MonoDevelop.Ide.Gui.Document, editor)
		return BooResolver(dom, doc.CompilationUnit, fileName)
		
def ParseBooText(fileName as string, text as string):
	
	pipeline = BLC.Pipelines.Parse()
	pipeline.Add(BLC.Steps.InitializeTypeSystemServices())
	pipeline.Add(BLC.Steps.IntroduceModuleClasses())
	
	compiler = BLC.BooCompiler()
	compiler.Parameters.Pipeline = pipeline
	compiler.Parameters.Input.Add(BLC.IO.StringInput(fileName, text))
	return compiler.Run()