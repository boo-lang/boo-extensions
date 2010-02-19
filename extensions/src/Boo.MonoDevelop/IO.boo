import System.IO

def PathCombine(*paths as (string)):
	path = paths[0]
	for part in paths[1:]:
		path = Path.Combine(path, part)
	return path
