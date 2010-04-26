namespace OMetaParserConsole

import System
import Boo.Lang.Compiler.Ast
import Boo.OMeta
import Boo.OMeta.Parser
import Boo.Lang.PatternMatching

def ReadBlock(line as string):
	newLine = System.Environment.NewLine
	buffer = System.Text.StringBuilder()
	buffer.Append(line)
	buffer.Append(newLine)
	while line=prompt("... "):
		break if 0 == len(line)
		buffer.Append(line)
		buffer.Append(newLine)
	return buffer.ToString()
	
macro WithColor:
	case [| WithColor $color |]:
		yield [|
			Console.ForegroundColor = $color
			$(WithColor.Body)
		|]
	
promptColor = ConsoleColor.DarkBlue
inputColor = ConsoleColor.Blue
resultColor = ConsoleColor.White
detailsColor = ConsoleColor.DarkGray
failureColor = ConsoleColor.DarkRed
while true:
	
	WithColor promptColor:
		Console.Write(">>> ")
	
	WithColor inputColor:
		line = Console.ReadLine()
		if line.EndsWith(":"):
			line = ReadBlock(line)
		if line == "/q":
			break
		line += "\n"
	
	match BooParser().stmt(line):
		case SuccessfulMatch(Input, Value):
			WithColor resultColor:
				print Value
			WithColor detailsColor:
				match Value:
					case ExpressionStatement(Expression: e):
						print "ExpressionStatement(${e.GetType()})"
					otherwise:
						print Value.GetType()
				print "{0}(IsEmpty: {1}, Position: {2})" % (Input.GetType(), Input.IsEmpty, Input.Position)
		case FailedMatch(Failure):
			WithColor failureColor:
				print Failure