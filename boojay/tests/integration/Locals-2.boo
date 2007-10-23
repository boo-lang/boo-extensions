"""
TRACE: 42
"""
import java.lang

def trace(s as string):
	builder = StringBuilder("TRACE: ")
	builder.append(s) # must be able to ignore value on the stack
	System.out.println(builder)
	
trace("42")