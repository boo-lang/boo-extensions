namespace Boo.MonoDevelop.Refactoring

import MonoDevelop.Refactoring
import Boo.MonoDevelop.ProjectModel

class BooASTProvider(INRefactoryASTProvider):
	def ParseFile(content as string):
		print "ParseFile(", content, ")"
		return null
		
	def ParseText(text as string):
		print "ParseText(", text, ")"
		return null
		
	def ParseExpression(text as string):
		print "ParseExpression(", text, ")"
		return null
		
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