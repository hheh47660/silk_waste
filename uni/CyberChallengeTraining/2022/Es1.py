import string


def isValid(old, new):
    if(len(new) < 8 or len(new) > 16): return 0

    contain_lower = False
    contain_upper = False
    contain_digit = False
    contain_special = False

    lower = string.ascii_lowercase
    upper = string.ascii_uppercase
    digit = string.digits
    punctuation = string.punctuation

    for i in range(len(new)):
        if not contain_lower: 
            if new[i] in lower: contain_lower = True
        if not contain_upper: 
            if new[i] in upper: contain_upper = True
        if not contain_digit: 
            if new[i] in digit: contain_digit = True
        if not contain_special: 
            if new[i] in punctuation: contain_special = True

        if i != 0 and new[i] == new[i -1]: return 0

        if len(new) == len(old):
            if new[:i] == old[:i] and new[i+1:] == old[i+1:]:
                return 0
        
        if len(new) == len(old) + 1:
            if (new[:i] + new[i+1:]) == old: 
                return 0

        if len(new) == len(old) - 1:
            if (old[:i] + old[i+1:]) == new: 
                return 0

    return int(contain_lower and contain_upper and contain_digit and contain_special)

            





N = int(input().strip())


for i in range(N):
    oldp, newp = input().split(" ")
    print(isValid(oldp, newp))
