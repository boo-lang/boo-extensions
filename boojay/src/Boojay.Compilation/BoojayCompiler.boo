namespace Boojay.Compilation

import Boo.Lang.Compiler
import java from IKVM.OpenJDK.ClassLibrary

def newBoojayCompiler():
	compiler = BooCompiler()
	compiler.Parameters.Pipeline = BoojayPipeline()
	compiler.Parameters.References.Add(typeof(lang.Object).Assembly)
	compiler.Parameters.References.Add(typeof(Boojay.Macros.PrintMacro).Assembly)
	return compiler
