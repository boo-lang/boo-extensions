"""
true
true
false
"""
import java.lang

def sysout(b as bool):
	System.out.println(b)
	
sysout "foo" isa string
sysout "foo" isa object
sysout "foo" isa Integer