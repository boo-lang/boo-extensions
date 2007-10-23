"""
before
1 is true
0 is false
after
"""
import java.lang

System.out.println("before")

a = 1
if a:
	System.out.println("1 is true")
	
a = 0
if a:
	System.out.println("0 is true")
else:
	System.out.println("0 is false")
	
System.out.println("after")