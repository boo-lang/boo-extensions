namespace Boo.MonoDevelop.ProjectModel

import MonoDevelop.Core
import MonoDevelop.Projects

import System.IO

import Boo.Lang.PatternMatching

class BooCompiler:
	
	_config as DotNetProjectConfiguration
	_selector as ConfigurationSelector
	_projectItems as ProjectItemCollection
	_compilationParameters as BooCompilationParameters
	_projectParameters as BooProjectParameters
	
	def constructor(
		config as DotNetProjectConfiguration,
		selector as ConfigurationSelector,
		projectItems as ProjectItemCollection,
		progressMonitor as IProgressMonitor):
		
		_config = config
		_selector = selector
		_projectItems = projectItems
		_compilationParameters = config.CompilationParameters or BooCompilationParameters()
		_projectParameters = config.ProjectParameters or BooProjectParameters()
		
	def Run() as BuildResult:
		responseFileName = Path.GetTempFileName()
		try:
			WriteOptionsToResponseFile(responseFileName)
			compilerOutput = ExecuteProcess(BoocPath(), "@${responseFileName}")
			return ParseBuildResult(compilerOutput)
		ensure:
			FileService.DeleteFile(responseFileName)
			
	private def BoocPath():
		return PathCombine(AssemblyPath(), "boo", "booc.exe")
		
	private def AssemblyPath():
		return Path.GetDirectoryName(GetType().Assembly.ManifestModule.FullyQualifiedName)
			
	private def WriteOptionsToResponseFile(responseFileName as string):
		options = StringWriter()
		
		options.WriteLine("-t:${OutputType()}")
		options.WriteLine("-out:${_config.CompiledOutputName}")
		
		options.WriteLine("-debug" + ("+" if _config.DebugMode else "-"))
		
		if _compilationParameters.Ducky: options.WriteLine("-ducky") 
		
		projectFiles = item as ProjectFile for item in _projectItems if item isa ProjectFile 
		for file in projectFiles:
			continue if file.Subtype == Subtype.Directory
			
			match file.BuildAction:
				case BuildAction.Compile:
					options.WriteLine("\"${file.Name}\"")
				case BuildAction.EmbeddedResource:
					options.WriteLine("-embedres:${file.FilePath},${file.ResourceId}")
				otherwise:
					print "Unrecognized build action for file", file, "-", file.BuildAction
				
		references = item as ProjectReference for item in _projectItems if item isa ProjectReference	
		for reference in references:
			for fileName in reference.GetReferencedFileNames(_selector):
				options.WriteLine("-reference:${fileName}")
		
		optionsString = options.ToString()
		print optionsString
		File.WriteAllText(responseFileName, optionsString)
		
	private def OutputType():
		return _config.CompileTarget.ToString().ToLower()
		
	private def ExecuteProcess(executable as string, commandLine as string):
		startInfo = System.Diagnostics.ProcessStartInfo(executable, commandLine,
						UseShellExecute: false,
						RedirectStandardOutput: true,
						RedirectStandardError: true)
		
		using process = Runtime.SystemAssemblyService.CurrentRuntime.ExecuteAssembly(startInfo, _config.TargetFramework):
			process.WaitForExit()
			return process.StandardOutput.ReadToEnd() + System.Environment.NewLine + process.StandardError.ReadToEnd()
			
	private def ParseBuildResult(stdout as string):
		
		result = BuildResult()
		
		for line in StringReader(stdout):
			match line:
				case @/^(?<fileName>.+)\((?<lineNumber>\d+),(?<column>\d+)\):\s+(?<code>.+?):\s+(?<message>.+)$/:
					result.Append(BuildError(
								FileName: fileName[0].Value,
								Line: int.Parse(lineNumber[0].Value),
								Column: int.Parse(column[0].Value),
								IsWarning: code[0].Value.StartsWith("BCW"),
								ErrorNumber: code[0].Value,
								ErrorText: message[0].Value))
					
				case @/^(?<code>.+):\s+(?<message>.+)$/:
					result.Append(
						BuildError(
								ErrorNumber: code[0].Value,
								ErrorText: message[0].Value))
					
				otherwise:
					if len(line) > 0: print "Unrecognized compiler output:", line
		
		return result
