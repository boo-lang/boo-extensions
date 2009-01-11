"""
0 = 0
1 = 1
2 = 2
3 = 3
4 = 4
"""
def foo():
	return i*2 for i in range(5)

current = 0
for i in foo():
	print current, "=", i / 2
	++current
