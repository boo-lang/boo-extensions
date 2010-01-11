namespace Boo.MonoDevelop.ProjectModel

import MonoDevelop.Core
import MonoDevelop.Projects
import System.Xml

class BooLanguageBinding(IDotNetLanguageBinding):
	
	ProjectStockIcon:
		get: return "md-boo-project"
	
	SingleLineCommentTag:
		get: return "#"
		
	BlockCommentStartTag:
		get: return "/*"
		
	BlockCommentEndTag:
		get: return "*/"
		
	Refactorer:
		get: return null
		
	Parser:
		get: return null
		
	Language:
		get: return "Boo"
		
	def IsSourceCodeFile(fileName as string):
		return fileName.ToLower().EndsWith(".boo")
		
	def GetFileName(baseName as string):
		return baseName + ".boo"
		
	def GetCodeDomProvider():
		return BooCodeDomProvider()
		
	def CreateProjectParameters(projectOptions as XmlElement):
		return BooProjectParameters()
		
	def CreateCompilationParameters(projectOptions as XmlElement):
		return BooCompilationParameters()
		
	def GetSupportedClrVersions():
		return (ClrVersion.Net_1_1, ClrVersion.Net_2_0, ClrVersion.Clr_2_1, ClrVersion.Net_4_0)
		
	def Compile(items as ProjectItemCollection,
				config as DotNetProjectConfiguration,
				progressMonitor as IProgressMonitor):
		return BooCompiler(config, items, progressMonitor).Run()

		
	
	