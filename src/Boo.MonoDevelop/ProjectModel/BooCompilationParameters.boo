namespace Boo.MonoDevelop.ProjectModel

import MonoDevelop.Projects
import MonoDevelop.Core.Serialization

class BooCompilationParameters(ConfigurationParameters):

	[ItemProperty("genwarnings")]
	[property(GenWarnings)] _genWarnings = false
	
	[ItemProperty("ducky")]
	[property(Ducky)] _ducky = false 

	[ItemProperty("culture")]
	[property(Culture)] _culture = ""