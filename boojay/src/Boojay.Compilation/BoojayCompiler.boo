namespace Boojay.Compilation

import Boo.Lang.Compiler

def newBoojayCompiler():
	compiler = BooCompiler()
	compiler.Parameters.Pipeline = BoojayPipeline()
	compiler.Parameters.References.Add(typeof(java.lang.String).Assembly)
	return compiler
