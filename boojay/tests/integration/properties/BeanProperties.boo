"""
"""
namespace properties

import java.util

d = Date(seconds: 42)
assert 42 == d.seconds
assert d.seconds == d.getSeconds()
