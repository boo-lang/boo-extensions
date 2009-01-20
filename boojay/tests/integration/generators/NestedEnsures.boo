"""
Test 0
=====
Test 1
begin outer try
outer ensure
Caught: Exception from outer ensure
=====
Test 2
begin outer try
begin middle try
middle ensure
outer ensure
Caught: Exception from outer ensure
=====
Test 3
begin outer try
begin middle try
innermost try
innermost ensure
middle ensure
outer ensure
Caught: Exception from outer ensure
=====
Test 4
begin outer try
begin middle try
innermost try
innermost try continues
innermost ensure
middle ensure
outer ensure
Caught: Exception from outer ensure
=====
"""
namespace generators

def nestedEnsures() as string*:
    try:
        yield "begin outer try"
        try:
            yield "begin middle try"
            try:
                yield "innermost try"
                print "innermost try continues"
            ensure:
                print "innermost ensure"
                raise "Exception from innermost ensure"
            yield "end middle try"
        ensure:
            print "middle ensure"
            raise "Exception from middle ensure"
        yield "end outer try"
    ensure:
        print "outer ensure"
        raise "Exception from outer ensure"

def consume(generator as string*, count as int):
    enumerator = generator.getEnumerator()
    try:
        for i in range(count):
            enumerator.moveNext()
            print enumerator.current
        enumerator.dispose()
    except ex:
        print "Caught: ${ex.getMessage()}"

for i in range(5):
    print "Test ${i}"
    consume(nestedEnsures(), i)
    print "====="
