#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>




int main(int argc, char *argv[]){
    
    int pid;
    int status;
    for (int i = 1; i < argc; i++){
        if ((pid = fork()) == 0){
            execlp(argv[i] , 0);
            printf("Error executing command %s\n", argv[i]);
            perror("Code error:");
            return -1;
        } else if (pid < 0){
            printf("Error creating new process for command %s\n", argv[i]);
            perror("Code error:");
            return -1;
        }
    }

    for (int i = 1; i < argc; i++){
        wait(&status);
        if (((status << 8) >> 8) == 0) {
            printf("Processes %d/%d terminated\n", i, argc - 1);
        }else{
            printf("Processes %d/%d terminated\n", i, argc - 1);
            printf("\tA process terminated with a signal code:%d\n", (status & 0xff));
        }

    }


}
