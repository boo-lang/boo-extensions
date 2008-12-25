namespace Boo.Lang.Runtime

static class RuntimeServices:
	
	def EqualityOperator(x, y):
		if x is y: return true
		if x is null: return false
		return x.Equals(y)