namespace Boojay.Compilation

import Boo.Lang.Compiler
import java from IKVM.OpenJDK.ClassLibrary

def newBoojayCompiler():
	compiler = BooCompiler()
	compiler.Parameters.Pipeline = BoojayPipeline()
	compiler.Parameters.References.Add(typeof(lang.Object).Assembly)
	return compiler


