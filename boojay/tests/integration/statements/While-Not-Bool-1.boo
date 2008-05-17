"""
before
not 0 is true
after
"""
import java.lang

System.out.println("before")

a = 0
while not a:
	System.out.println("not 0 is true")
	a += 1
	
System.out.println("after")