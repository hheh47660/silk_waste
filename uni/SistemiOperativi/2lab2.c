#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

void copy_file(char *dst, char *src, char *file){
    char new_dir_path[256];
    strcpy(new_dir_path, dst);
    strcat(new_dir_path, "/");
    strcat(new_dir_path, file);

    char new_file_path[256];
    strcpy(new_file_path, src);
    strcat(new_file_path, "/");
    strcat(new_file_path, file);

	printf("\n[INFO %d] Copying %s\n", getpid(), file);

    execlp("/bin/cp", "cp", new_file_path, new_dir_path, (char *) 0);
    perror("[ERROR] Error copying file\n");
    exit(0);
}

void rm_file(char *dir, char *file){
    char new_file_path[256];
    strcpy(new_file_path, dir);
    strcat(new_file_path, "/");
    strcat(new_file_path, file);
	printf("\n[INFO %d] Removing %s\n", getpid(), file);
    printf("\n");

    execl("/bin/rm", "rm", new_file_path, (char *) 0);
    perror("[ERROR] Error removing file\n");
    exit(0);
}

int main(int argc, char *argv[]){

	int status;

	if(argc < 4){
		printf("Usage: %s [dir1] [dir2] [files] ...\n", argv[0]);
		return -1;
	}

    for (int i = 0; i < argc - 3; i++){
        int pid = fork();
        if (pid < 0) {
            printf("[ERROR] Error creating child\n");
            return -1;
        }
	    if(pid != 0) continue;

        if (getpid() % 2 == 0) copy_file(argv[2], argv[1], argv[i + 3]);
        rm_file(argv[1], argv[3 + i]);
        
    }


	for(int i = 0; i < argc - 3; i++){
		int child_pid = wait(&status);
		if(WIFEXITED(status)){
            continue;
		}else{
			printf("[PID %d] Child %d ended unexpectly with signal code: %d\n",getpid(), child_pid, WTERMSIG(status));
            return -1;
		}

	}
	
    execlp("/bin/ls", "ls", argv[2]);





}
