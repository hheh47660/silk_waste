import string

def checkPhrase(p, b):
    for word in b:
        if word in p:
            print("BANNED")
            return
    print("SAFE")
    return

tmp = input().split()
N = int(tmp[0])
M = int(tmp[1])
bannedWords = []
phrases= []

for _ in range(M):
    bannedWords.append(input().strip())

for _ in range(N):
    checkPhrase(input().strip(), bannedWords)

