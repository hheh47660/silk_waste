#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>


/* n is the index in the array to get the process from */
void newProc(int n, char *argv[], int argc){
    
    if (n >= argc){
        printf("[INFO] Node child terminated, my pid is %d\n", getpid());
        exit(0);
    }

    int pid = fork();
    if (pid > 0){
        printf("[New Process %d/%d] PID %d for command %s\n",n, argc - 1, pid, argv[n]);
        execlp(argv[n], 0);
        printf("[Error] Could not execute command %s at iteration %d\n", argv[n], n);
        perror("\tError code: ");
        exit(0);
    }else if( pid == 0){
        newProc(n + 1, argv, argc);
    }else{
        printf("[Error] Could not create child for command %s at iteration %d\n", argv[n + 1], n+1);
        perror("\tError code: ");
        exit(0);
    }
}


int main(int argc, char *argv[]){

    newProc(1, argv, argc);
    return 0;
}
