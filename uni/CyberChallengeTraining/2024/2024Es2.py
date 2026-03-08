import string

def execIns(instrs):
    regs = {
        "a" : 0,
        "b" : 0,
        "c" : 0,
        "d" : 0,
        "e" : 0,
        "f" : 0
    }

    labels = {}

    pc = 0
    while pc < len(instrs):
        ins = instrs[pc]
        args = ins.split()
        match args[0].strip():
            case 'add':
                regs |= {args[1].strip() : int(regs.get(args[1].strip())) + int(args[2].strip())}
            case 'sub':
                regs |= {args[1].strip() : int(regs.get(args[1].strip())) - int(args[2].strip())}
            case 'mul':
                regs |= {args[1].strip() : int(regs.get(args[1].strip())) * int(args[2].strip())}
            case 'lab':
                labels |= {args[1].strip() : pc}
            case 'jmp':
                if regs.get(args[1].strip()) == int(args[2].strip()):
                    pc = labels.get(args[3].strip())

        pc += 1

    return sum(regs.values())


N = int(input().strip())



instructions = []

for _ in range(N):
   instructions.append(input().strip())



print(execIns(instructions))

