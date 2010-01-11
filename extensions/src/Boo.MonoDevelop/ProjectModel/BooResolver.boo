namespace Boo.MonoDevelop.ProjectModel

import MonoDevelop.Projects.Dom
import MonoDevelop.Projects.Dom.Parser

import MonoDevelop.Ide.Gui

import Boo.Lang.Compiler as BLC

class BooResolver(IResolver):
	def constructor(dom as ProjectDom, compilationUnit as ICompilationUnit, textEditor as TextEditor, fileName as string):
		pass
		
	def Resolve(result as ExpressionResult, location as DomLocation):
		print "BooResolver.Resolve(", result, ",", location, ")"