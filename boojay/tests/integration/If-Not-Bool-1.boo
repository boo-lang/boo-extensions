"""
before
not 1 is false
not 0 is true
after
"""
import java.lang

System.out.println("before")

a = 1
if not a:
	System.out.println("not 1 is true")
else:
	System.out.println("not 1 is false")
	
a = 0
if not a:
	System.out.println("not 0 is true")
else:
	System.out.println("0 is false")
	
System.out.println("after")