"""
before
true
true
after
"""
import java.lang

System.out.println("before")

a = 2
while a:
	System.out.println("true")
	a -= 1
	
a = 0
while a:
	System.out.println("0 is true")
	
System.out.println("after")