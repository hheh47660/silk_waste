import string


def resolve(numbers):
    s = list(sorted(numbers))
    res = -1

    for i in range(len(s)):
        if numbers[i] != s[i]:
            res += 1

    return max(0, res)


    









N = int(input().strip())


numbers = list(map(int, input().strip().split()))


print(resolve(numbers))
