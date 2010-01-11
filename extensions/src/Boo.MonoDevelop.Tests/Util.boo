namespace Boo.MonoDevelop.Tests

import MonoDevelop.Projects
import MonoDevelop.Projects.Dom.Parser

import System.IO
import UnitTests.Util
		
def CreateSingleFileProject(projectName as string, code as string):
	tempFile = PathCombine(TmpDir, "Boo.MonoDevelop", projectName, projectName + ".boo")
	Directory.CreateDirectory(Path.GetDirectoryName(tempFile))
	File.WriteAllText(tempFile, code)
	return Services.ProjectService.CreateSingleFileProject(tempFile)
	
def PathCombine(*parts as (string)):
	path = parts[0]
	for part in parts[1:]:
		path = Path.Combine(path, part)
	return path
	
def GetProjectDom(project as Project):
	ProjectDomService.Load(project)
	dom = ProjectDomService.GetProjectDom(project)
	dom.ForceUpdate()
	return dom