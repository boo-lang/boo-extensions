namespace Boo.MonoDevelop.Completion

import MonoDevelop.Projects.Dom
import MonoDevelop.Projects.Dom.Parser 
import MonoDevelop.Ide.Gui.Content
import MonoDevelop.Projects.Gui.Completion

import Boo.Lang.PatternMatching

class BooEditorCompletion(CompletionTextEditorExtension):
	
	_dom as ProjectDom
	
	override def Initialize():
		super()
		_dom = ProjectDomService.GetProjectDom(Document.Project) or ProjectDomService.GetFileDom(Document.FileName)
		
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
		print "HandleCodeCompletion(${context.ToString()}, ${completionChar.ToString()})"
		
		match completionChar.ToString():
			case ' ':
				lineText = GetLineText(context.TriggerLine)
				if not lineText.StartsWith("import "):
					return null
					
				return ImportCompletionDataFor('')
				
			case '.':
				lineText = GetLineText(context.TriggerLine)
				if not lineText.StartsWith("import "):
					return null
				
				nameSpace = lineText[len("import "):context.TriggerLineOffset-2].Trim()
				return ImportCompletionDataFor(nameSpace)
				
			otherwise:
				return null
				
	def ImportCompletionDataFor(nameSpace as string):
		print "ImportCompletionDataFor(${nameSpace})"
		
		result = CompletionDataList()
		for member in _dom.GetNamespaceContents(nameSpace, true, true):
			result.Add(member.Name, member.StockIcon)
		return result
				
	def GetLineText(line as int):
		return Document.TextEditor.GetLineText(line)
		
	