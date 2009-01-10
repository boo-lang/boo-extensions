namespace Boojay.Lang

import java.io
import java.lang from IKVM.OpenJdk.ClassLibrary

def join(items):
	return join(items, ' ')

def join(items, separator):
	builder = StringBuilder()
	first = true
	for item in items:
		if first:
			first = false
		else:
			builder.append(separator)
		builder.append(item)
	return builder.toString()
	
def prompt(msg as string):
	System.out.print(msg)
	return BufferedReader(InputStreamReader(System.get_in())).readLine()

	