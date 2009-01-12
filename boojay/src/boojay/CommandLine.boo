namespace boojay

import System.IO
import Boo.Lang.Useful.CommandLine from Boo.Lang.Useful

class CommandLine(AbstractCommandLine):
	
	[getter(References)]
	_references = []
	
	_sourceFiles = []
	
	_srcDirs = []

	def constructor(argv):
		Parse(argv)
		
	def SourceFiles():
		
		for srcFile as string in _sourceFiles:
			yield srcFile
			
		for srcDir in _srcDirs:
			for fname in Directory.GetFiles(srcDir, "*.boo"):
				yield fname
		
	IsValid:
		get: return len(self._sourceFiles) > 0 or len(self._srcDirs) > 0
		
	[Option("Output directory", ShortForm: "o", LongForm: "out")]
	public OutputDirectory = "."
		
	[Option("Prints the resulting bytecode to stdout.", ShortForm: 'p', LongForm: "print")]
	public PrintCode = false
	
	[Option("Prints the expanded boo code to stdout.", LongForm: "boo")]
	public Boo = false

	[Option("Enables duck typing.", LongForm: "ducky")]
	public Ducky = false
	
	[Option("Enables writing debug symbols.", LongForm: "debug")]
	public Debug = false
	
	[Option("Enables verbose mode.", LongForm: "verbose")]
	public Verbose = false
	
	[Option("Prints additional compiler internal messages to stdout.", LongForm: "debug-compiler")]
	public DebugCompiler = false 

	[Option("References the specified {assembly}", ShortForm: 'r', LongForm: "reference", MaxOccurs: int.MaxValue)]
	def AddReference(reference as string):
		_references.AddUnique(reference)
		
	[Option("Includes all *.boo files from {srcdir}", LongForm: "srcdir", MaxOccurs: int.MaxValue)]
	def AddSourceDir(srcDir as string):
		_srcDirs.AddUnique(Path.GetFullPath(srcDir))
		
	[Option("display this help and exit", LongForm: "help")]
	public DoHelp = false
		
	[Argument]
	def AddSourceFile([required] sourceFile as string):
		self._sourceFiles.Add(sourceFile)
