import string

def printMatrix(result):
    for i in range(N):
        line = ""
        for j in range(M):
            line += result[i][j]
        print(line)

def emptyCell(n, m, old_state):
    not_empty_cells = 0
    for i in range(max(0, n - 1), min(len(old_state), n + 2)): ##righe
        for j in range(max(0, m - 1), min(len(old_state[0]), m + 2)): #colonne
            if not(n == i and m == j):
                if old_state[i][j] != '.': 
                    not_empty_cells += 1

    if not_empty_cells > 4 :
        return '+'
    else :
        return '.'

def dataCell(n, m, old_state):
    not_empty_cells = 0
    for i in range(max(0, n - 1), min(len(old_state), n + 2)): ##righe
        for j in range(max(0, m - 1), min(len(old_state[0]), m + 2)): #colonne
            if not(n == i and m == j):
                if old_state[i][j] != '.': 
                    not_empty_cells+= 1

    if not_empty_cells > 4:
        return '*'
    elif not_empty_cells == 4:
        return '+' 
    else : 
        return '.'


def malwareCell(n, m, old_state):
    not_empty_cells = 0
    for i in range(max(0, n - 1), min(len(old_state), n + 2)): ##righe
        for j in range(max(0, m - 1), min(len(old_state[0]), m + 2)): #colonne
            if not (n == i and m == j):
                if old_state[i][j] != '.': 
                    not_empty_cells+= 1

    if not_empty_cells > 4:
        return '+'
    elif not_empty_cells == 4:
        return '*' 
    else : 
        return '.'



def propagate(state, k, n, m):
    old_state = state


    for _ in range(k):

        new_state = [['.' for _ in range(m)] for _ in range(n)]
 
        for i in range(n):
            for j in range(m):
                match old_state[i][j]:
                    case '.':
                        new_state[i][j] = emptyCell(i, j, old_state)
                    case '+':
                        new_state[i][j] = dataCell(i, j, old_state)
                    case '*':
                        new_state[i][j] = malwareCell(i, j, old_state)
            


        old_state = new_state



    return new_state


N, M, K = map(int, input().strip().split())


state = [["." for _ in range(M)] for _ in range(N)]

for r in range(N):
    line = input().strip()
    for c in range(M):
        state[r][c] = line[c]



result = propagate(state, K, N, M)
printMatrix(result)


