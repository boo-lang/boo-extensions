"""
[2, 6, 10, 14, 18]
"""
namespace generators

a = [i*2 for i in range(10) if i % 2]
print a