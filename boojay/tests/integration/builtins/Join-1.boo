"""
foo bar
foo, bar
"""
list = java.util.ArrayList()
list.add("foo")
list.add("bar")
print join(list)
print join(list, ", ")