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
	
def parseCommandLine(argv as (string)):
	try:
		cmdLine = CommandLine(argv)
		if (not cmdLine.IsValid) or cmdLine.DoHelp:
			cmdLine.PrintOptions()
			return null
		return cmdLine
	except x:
		print "BCE000: ", x.Message
		return null

print "boojay .0a"

cmdLine = parseCommandLine(argv)
if cmdLine is null: return

compiler = newBoojayCompiler(cmdLine.Boo and BoojayPipelines.ProduceBoo() or BoojayPipelines.ProduceBytecode())
params = compiler.Parameters

for fname in cmdLine.SourceFiles():
	if cmdLine.Verbose: print fname
	params.Input.Add(FileInput(fname))
	
for reference in cmdLine.References:
	params.References.Add(loadAssembly(reference))
	
params.OutputAssembly = cmdLine.OutputDirectory
if cmdLine.DebugCompiler:
	params.EnableTraceSwitch()
	params.TraceLevel = System.Diagnostics.TraceLevel.Verbose
	Trace.Listeners.Add(TextWriterTraceListener(Console.Error))

result = compiler.Run()
for error in result.Errors:
	print error.ToString(cmdLine.Verbose)
for warning in result.Warnings:
	print warning
