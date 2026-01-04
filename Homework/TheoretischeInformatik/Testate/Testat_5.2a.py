import math

def f(x,k):
    if k >= x*x:
        return k-x*x
    return 0

def g(k):
    return math.ceil(math.sqrt(k))

_x, _k = 26, 50
biggest_k = len(str(_k))

for x in range(_x):
    for k in range(_k):
        fv = str(f(x,k))
        colored = int(x == g(k))
        print("\x1b[31m" * colored,
              " " * (biggest_k-len(fv)) + fv,
              "\x1b[0m" * colored, sep="", end=" ")
    print()

for i in range(1,1000):
    assert(f(g(i),i) == 0)
    for j in range(0,g(i)):
        assert(f(j,i) > 0)