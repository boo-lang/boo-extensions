namespace Boojay.Lang

import java.io
import java.lang from IKVM.OpenJdk.ClassLibrary

def range(begin as int, end as int):
	if begin < end:
		i = begin
		while i < end:
			yield i
			++i
	else:
		i = begin
		while i > end:
			yield i
			--i

def range(max as int):
	assert max >= 0
	return range(0, max)

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

	