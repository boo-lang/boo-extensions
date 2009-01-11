"""
1
1
2
3
5
8
"""
namespace generators

def fibonacciUpTo(max as int):
	a, b = 1, 1
	while a < max:
		yield a
		a, b = b, a + b
		
for i in fibonacciUpTo(10):
	print i
		
