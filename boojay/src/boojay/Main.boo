namespace boojay

import System.Reflection
import System.IO
import Boo.Lang.Compiler.IO
import Boojay.Compilation

def loadAssembly(name as string):
	if File.Exists(name):
		return Assembly.LoadFrom(name)
	return Assembly.Load(name)

print "boojay .0a"

cmdLine = CommandLine(argv)
if (not cmdLine.IsValid) or cmdLine.DoHelp:
	cmdLine.PrintOptions()
	return

compiler = newBoojayCompiler()
for fname in cmdLine.SourceFiles():
	compiler.Parameters.Input.Add(FileInput(fname))
	
for reference in cmdLine.References:
	compiler.Parameters.References.Add(loadAssembly(reference))
	
result = compiler.Run()
for error in result.Errors:
	print error.ToString(cmdLine.Verbose)
