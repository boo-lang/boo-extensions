namespace boojay

import System
import System.Reflection
import System.Diagnostics
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
params = compiler.Parameters

for fname in cmdLine.SourceFiles():
	if cmdLine.Verbose: print fname
	params.Input.Add(FileInput(fname))
	
for reference in cmdLine.References:
	params.References.Add(loadAssembly(reference))
	
params.OutputAssembly = cmdLine.OutputDirectory or ""
if cmdLine.Verbose:
	params.EnableTraceSwitch()
	params.TraceLevel = System.Diagnostics.TraceLevel.Verbose
	Trace.Listeners.Add(TextWriterTraceListener(Console.Error))

result = compiler.Run()
for error in result.Errors:
	print error.ToString(cmdLine.Verbose)
