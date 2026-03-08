import string

def getLeft(S, D):
    res = [0]*len(S)
    j = 0
    for i in range(len(S)):
        while j < len(S) and S[i] - S[j] > D:
            print(S[i], S[j])
            j += 1
        res[i] = j
    return res


def getRight(S, D):
    res = [0]*len(S)
    j = len(S) - 1
    for i in range(len(S)-1, -1, -1):
        while j >= 0 and S[j] - S[i] > D:
            j -= 1
        res[i] = j
    return res


def solve(S, D):
    S = sorted(S)
    lm = getLeft(S, D)
    rm = getRight(S, D)

    ls = [0]*len(S)
    rs = [0]*len(S)
    ans = 0

    for i in range(len(S)):
        ls[i] = i - lm[i] + 1
        if i > 0:
            ls[i] = max(ls[i], ls[i-1])

    for i in range(len(S) - 1, -1, -1):
        rs[i] = rm[i] - i + 1
        if i < len(S) - 1:
            rs[i] = max(rs[i], rs[i+1])

    for i in range(len(S)-1):
        ans = max(ans, ls[i] + rs[i+1])

    return ans



T = int(input().strip())




for _ in range(T):
    N, D = map(int, input().split())
    S = map(int, input().strip().split())
    print(solve(S, D))

