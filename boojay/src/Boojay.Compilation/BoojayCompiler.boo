namespace Boojay.Compilation

import Boo.Lang.Compiler
import java from IKVM.OpenJDK.ClassLibrary

def newBoojayCompiler():
	return newBoojayCompiler(BoojayPipelines.ProduceBytecode())
	
def newBoojayCompiler(pipeline as CompilerPipeline):
	compiler = BooCompiler()
	compiler.Parameters.Pipeline = pipeline
	compiler.Parameters.References.Add(typeof(lang.Object).Assembly)
	compiler.Parameters.References.Add(typeof(Boojay.Macros.PrintMacro).Assembly)
	compiler.Parameters.References.Add(typeof(Boojay.Runtime.BuiltinsModule).Assembly)
	return compiler
