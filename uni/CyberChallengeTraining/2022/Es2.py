import string


def result(bottoms, tops, k):
    bottoms.sort()
    tops.sort()


    n_intervals = 0
    res = 0


    l = bottoms[0]

    bi = 0
    ti = 0
    for i in range(len(tops)):

        if(bottoms[bi] <= tops[ti]):
            if n_intervals == k: res += bottoms[bi] - l 
            l = bottoms[bi]
            n_intervals += 1
            bi += 1
        elif(bottoms[bi] > tops[ti]):
            if n_intervals == k: res += tops[ti] - l + 1
            l = tops[ti]
            n_intervals -= 1
            ti += 1

    return res






N, K = map(int, input().strip().split())
bottoms = []
tops = []


for i in range(N):
    bottom, top = input().split(" ")
    bottoms.append(int(bottom))
    tops.append(int(top))

print(result(bottoms, tops, K))
