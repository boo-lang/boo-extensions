"""
4
8
"""
def square(i as int):
	return i*i
	
def cube(i as int):
	return i*i*i
	
fn = square
print fn(2)

fn = cube
print fn(2)