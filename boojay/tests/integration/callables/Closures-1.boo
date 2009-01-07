"""
<html>
<head>
<title>it works</title>
</head>
</html>
"""
def html(block as callable()):
	tag "html", block
	
def head(block as callable()):
	tag "head", block
	
def title(text):
	print "<title>${text}</title>"

def tag(tagName, block as callable()):
	print "<${tagName}>"
	block()
	print "</${tagName}>"
	
html:
	head:
		title "it works"