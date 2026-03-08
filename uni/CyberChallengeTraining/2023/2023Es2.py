import string


def rank(points, tines, M):
    rank = []
    for i in range(M):
        rank.append((i, points[i], max(times[i])))

    rank = sorted(rank, key= lambda k : (k[1] -k[2], -k[0]), reverse=True)

    for id, point, time in rank:
        print(f"{id + 1} {point}")



M, N, S = map(int, input().strip().split())

questionsPoints = [0] * (N + 1)
questionsRes = [0] * (N + 1)
playersScores = []
times = [[0]* (N + 1) for _ in range(M)]
points = [0] * M

for i in range(N):
    id, res, p = input().strip().split()
    questionsRes[int(id)] = res
    questionsPoints[int(id)] = p

for i in range(M):
    pid, tid, res, time = input().strip().split()
    times[int(pid) - 1][int(tid)] = int(time)
    if res == questionsRes[int(tid)]:
        points[int(pid) - 1] += int(questionsPoints[int(tid)])


rank(points, times, M)
