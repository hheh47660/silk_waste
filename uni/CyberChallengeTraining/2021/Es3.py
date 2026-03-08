import string

def mod1(workers, k):
    
    res = workers[-1]

    if workers[0] != 0:
        k -= 1
        res += workers[0]

    for i in workers[-2:-k - 2: -1]:
        res += i

    return res

def mod2(workers, k):
    
    res = workers[-1]

    for i in workers[-2:-k - 2: -1]:
        res += i

    return res

def maxUnbalance(workers, k):
    workers.sort()
    
    res = workers[-1]

    mod1c = mod1(workers, k)
    mod2c = mod2(workers, k)

    if mod1c > mod2c: return mod1c
    return mod2c
        




N, K = map(int, input().strip().split())


workers = list(map(int, input().strip().split()))

print(maxUnbalance(workers, K))
