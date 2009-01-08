def square(i as int):
	return i*i
	
function as callable(object) as object = square
for item in (1, 2, 3):
	print function(item)