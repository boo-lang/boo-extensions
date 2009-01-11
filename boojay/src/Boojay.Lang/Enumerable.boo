namespace Boojay.Lang

interface Enumerable:
	def GetEnumerator() as Enumerator

interface Enumerator(Disposable):
	def MoveNext() as bool
	Current as object:
		get