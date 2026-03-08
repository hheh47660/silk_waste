import string


def check(word, line):
    j = 0
    for i in range(len(line)):
        if line[i:i+len(word)] == word:
            j = 0
        else:
            j += 1

        if(j >= len(word)):
            return False


    return True

def solve(line):
    res = 0
    for i in range(len(line)):
        word = line[:i+1]
        
        if(check(word, line)):
            res += 1

    return res



T = int(input().strip())




for _ in range(T):
    N, M = map(int, input().split())
    alphabet = input().strip()
    line = input().strip()
    print(solve(line))

