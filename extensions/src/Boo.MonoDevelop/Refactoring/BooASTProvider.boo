namespace Boo.MonoDevelop.Refactoring

import MonoDevelop.Refactoring
import Boo.MonoDevelop.ProjectModel
import Boo.Lang.PatternMatching
import ICSharpCode.NRefactory.Ast
import System.Collections.Generic

class BooASTProvider(INRefactoryASTProvider):
	def ParseFile(content as string):
		print "ParseFile(", content, ")"
		
	def ParseText(text as string):
		match text:
			case /class\s+(?<className>(.+?))\b/:
				return TypeReferenceExpression(className[0].Value)
			otherwise:
				return null
		
	def ParseExpression(text as string):
		print "ParseExpression(", text, ")"
		return ParseText(text)
		
	def ParseTypeReference(text as string):
		print "ParseTypeReference(", text, ")"
		
	def CanGenerateASTFrom(mimeType as string):
		return mimeType == BooMimeType
	
/*
string OutputNode (ProjectDom dom, INode node);
string OutputNode (ProjectDom dom, INode node, string indent);

INode ParseText (string text);
Expression ParseExpression (string expressionText);
CompilationUnit ParseFile (string content);
TypeReference ParseTypeReference (string typeText);

bool CanGenerateASTFrom (string mimeType);
*/