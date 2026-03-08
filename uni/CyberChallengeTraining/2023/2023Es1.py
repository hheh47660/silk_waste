import string


def resolve(ans, res):
    result = 0
    for i in range(len(ans)):
        if(ans[i] == res[i]):
            result += 1
    return result



Q, N = map(int, input().strip().split())

responses = input().strip()

for i in range(N):
    print(resolve(input().strip(), responses))
