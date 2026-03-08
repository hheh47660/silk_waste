import string


def dicOfLetters(word):
    res = {}
    for c in word:
        if c in res.keys():
            res.update({c : res.get(c) + 1})
        else:
            res.update({c : 1})
    return res

def verifyHash(password, hash):
    i = 0

    letters = dicOfLetters(password)

    while i < (len(hash) - len(password)):

        v = hash[i:i+len(password) ]
        ref = letters.copy()

        for c in v:
            if c in ref.keys():
                ref.update({c : ref.get(c) - 1})


        #print(f"password: {password}\n\tsubstring: {v}\n\tdic:{ref}")

        if all(i == 0 for i in ref.values()):
            return 1
        else:
            for j in ref.values():
                if j >= 0:
                    i += j

    return 0
    


N = int(input().strip())


for _ in range(N):
    password = input().strip()
    hash = input().strip()

    print(verifyHash(password, hash))
