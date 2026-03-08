import string


def minWorkers(times, T):
    lo = 1
    hi = len(times) + 1

    while lo < hi:
        medium = lo + (hi - lo) // 2
        if timeNeeded(times, medium) <= T:
            hi = medium
        else:
            lo = medium + 1

    return medium



def timeNeeded(times, w):
    workers = [0] * w
    r = 0
    i = 0
    while r < len(times):
        if workers[i] == min(workers):
            workers[i] += times[r]
            r = r + 1
        i = (i + 1) % w

    return max(workers)



N, T = map(int, input().strip().split())
times = input().strip().split()

for i in range(N):
    times[i] = int(times[i])


print(minWorkers(times, T))

