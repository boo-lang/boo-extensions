namespace Boojay.Macros

import java.io
import java.lang

def join(items):
	builder = StringBuilder()
	enumerator = iteratorFor(items)
	while enumerator.hasNext():
		builder.append(enumerator.next())
	return builder.toString()
	
def prompt(msg as string):
	System.out.println(msg)
	return BufferedReader(InputStreamReader(System.get_in())).readLine()
	
def iteratorFor(source):
	return (source as Iterable).iterator()