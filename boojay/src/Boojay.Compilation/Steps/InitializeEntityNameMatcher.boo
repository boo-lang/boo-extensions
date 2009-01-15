namespace Boojay.Compilation.Steps

import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.TypeSystem

class InitializeEntityNameMatcher(AbstractCompilerStep):
	override def Run():
		NameResolutionService.EntityNameMatcher = MatchIgnoringFirstLetterCase
	
	def MatchIgnoringFirstLetterCase(entity as IEntity, name as string):
		entityName = entity.Name
		if len(entityName) != len(name):
			return false
		if char.ToLower(entityName[0]) != char.ToLower(name[0]):
			return false
		for i in range(1, entityName.Length):
			if entityName[i] != name[i]:
				return false
		return true