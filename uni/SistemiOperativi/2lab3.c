#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <dirent.h>
#include <errno.h>
#include <stdlib.h>

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

void rename_file(char *src, char *file, char *new_name){
    char old_file_path[256];
    strcpy(old_file_path, src);
    strcat(old_file_path, "/");
    strcat(old_file_path, file);

    char new_file_path[256];
    strcpy(new_file_path, src);
    strcat(new_file_path, "/");
    strcat(new_file_path, new_name);

	printf("\n[INFO %d] Renaming %s to %s\n", getpid(), file, new_name);

    execlp("/bin/mv", "mv", old_file_path, new_file_path, (char *) 0);
    perror("[ERROR] Error renaming file\n");
    exit(0);
}

int test_dir(char *dir_name){
    DIR* dir = opendir(dir_name);
    if (dir) {
        /* Directory exists. */
        closedir(dir);
        return 0;
    } else if (ENOENT == errno) {
        /* Directory does not exist. */
		printf("[ERROR] Dir %s does not exist\n", dir_name);
        return -1;
    } else {
        /* opendir() failed for some other reason. */
        perror("[ERROR] Error checking for dir\n");
        return -1;
        
    }
}



int main(int argc, char *argv[]){

	int status;

	if(argc < 4){
		printf("Usage: %s [dir1] [dir2] [files] ...\n", argv[0]);
		return -1;
	}

    if(test_dir(argv[1]) == -1){
        return -1;
    }
    if(test_dir(argv[2]) == -1){
        return -1;
    }

    for (int i = 0; i < argc - 3; i++){
        int pid = fork();
        if (pid < 0) {
            printf("[ERROR] Error creating child\n");
            return -1;
        }
	    if(pid != 0) continue;
    
        /* children proc : needs to create a nephew
         *                 wait for it
         *                 and then move that file */
        
        pid = fork();
        int status;
        if (pid < 0) {
            printf("[ERROR] Error creating nephew\n");
            return -1;
        }
	    if(pid != 0) {
            wait(&status);
            
            /* children proc : move file */
            if(WIFEXITED(status)){
                printf("[PID %d] Nephew for file %s ended without errors\n", getpid(), argv[3 + i]);
            }else{
                printf("[PID %d] Nephew for file %s ended unexpectly with status code: %d\n",getpid(), argv[3 + i], WTERMSIG(status));
                continue;
            }

            char pid_as_string[64];
            snprintf(pid_as_string, 64, "%d", getpid());
            rename_file(argv[1], argv[3 + i], pid_as_string);
        }
        
        /* nephew proc : copy file */
        copy_file(argv[2], argv[1], argv[3 + i]);
    }
}
