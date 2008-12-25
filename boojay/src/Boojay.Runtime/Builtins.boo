namespace Boojay.Runtime

import java.io
import java.lang

def join(items):
	builder = StringBuilder()
	for item in items:
		builder.append(item)
	return builder.toString()
	
def prompt(msg as string):
	System.out.println(msg)
	return BufferedReader(InputStreamReader(System.get_in())).readLine()
	