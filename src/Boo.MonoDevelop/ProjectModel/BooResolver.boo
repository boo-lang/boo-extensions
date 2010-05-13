namespace Boo.MonoDevelop.ProjectModel

import MonoDevelop.Projects.Dom
import MonoDevelop.Projects.Dom.Parser

class BooResolver(IResolver):
	_dom as ProjectDom
	_compilationUnit as ICompilationUnit

	def constructor(dom as ProjectDom, compilationUnit as ICompilationUnit, fileName as string):
		_dom = dom
		_compilationUnit = compilationUnit
		
	def Resolve(result as ExpressionResult, location as DomLocation):
		type = TypeAt(location)
		if type is not null:
			return MemberResolveResult(type)
		return null
		
	private def TypeAt(location as DomLocation):
		if _compilationUnit is null:
			return null
			
		for type in _compilationUnit.Types:
			if type.BodyRegion.Contains(location):
				return type