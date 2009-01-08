"""
[]
[1, 2, foo]
1
2
foo
"""
l1 = []
l2 = [1, 2, "foo"]

print l1
print l2

for item in l2:
	print item
	
l3 = [1, 2]
l4 = [1, 2]
assert l3 == l4


