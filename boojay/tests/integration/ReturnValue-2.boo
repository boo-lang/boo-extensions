"""
before
ltuae
after
"""
import java.lang

def ltuae():
	sysout "ltuae"
	return "42"
	
def sysout(s as string):
	System.out.println(s)

sysout "before"	
ltuae()
sysout "after"
