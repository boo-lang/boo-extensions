"""
loop 0
0
loop 1
0
1
loop 2
0
1
2
"""
namespace statements

def foo(steps as int):
	print "0"
	if steps < 1:
		return
	print "1"
	if steps < 2:
		return
	print "2"
	
for i in range(3):
	print "loop", i
	foo(i)