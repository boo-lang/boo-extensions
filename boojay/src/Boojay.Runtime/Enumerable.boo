namespace Boojay.Runtime

interface Enumerable:
	def GetEnumerator() as Enumerator

interface Enumerator:
	def MoveNext() as bool
	Current as object:
		get