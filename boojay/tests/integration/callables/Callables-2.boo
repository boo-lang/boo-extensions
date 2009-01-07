"""
4
8
"""
callable IntFunction(i as int) as int

def square(i as int):
	return i*i
	
def cube(i as int):
	return i*i*i
	
fn as IntFunction
fn = square
print fn(2)

fn = cube
print fn(2)