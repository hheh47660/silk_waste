#include <sys/wait.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>


#define N 8

void count_clothes(char sold_clothes[], char *clothes_type){
	printf("[PID %d] Launching child to count clothes of type %s\n", getpid(), clothes_type);
	int pid = fork();
	if (pid < 0) {
		printf("[ERROR] Error creating child to count clothes of type %s\n", clothes_type);
		return;
	}
	if(pid != 0) return;

	int result = 0;

	for(int i = 0; i < N; i++){
		if(sold_clothes[i] == clothes_type[0])
			result++;
	}

	exit(result);
}

void count_belts(char *filename){

	printf("[PID %d] Launching child to count belts\n", getpid());
	int pid = fork();
	if (pid < 0) {
		printf("[ERROR] Error creating child to count belts\n");
		return;
	}
	if(pid != 0) return;

	// count words with wc
	printf("[PID %d] Number of belts: ", getpid());
	execl("/bin/wc", "wc", "-l", filename, 0);
	perror("[ERROR] Error executing command wc");
	
}


int main(int argc, char *argv[]){

	int status;

	if(argc < 3){
		printf("Usage: %s [file] [vestiti] ...\n", argv[0]);
		return -1;
	}

	/* part 1 */ 
	count_belts(argv[1]);
	wait(&status);

	if(WIFEXITED(status)){
		printf("[PID %d] Child for couting belts ended without errors\n", getpid());
	}else{
		printf("[PID %d] Child for couting belts ended unexpectly with status code: %d\n",getpid(), WTERMSIG(status));
	}


	/* part 2 */ 
	
	/* create sold_clothes array with random values */
	char sold_clothes[N];
	char letters[] = "abcdefgh";
	int child_pids[64];
	char child_types[64];
	int n_child = 0;
    int total = 0;

	for(int i = 0; i < N; i++){
		if (i == 0) printf("Array: [");
		sold_clothes[i] = (char) letters[rand() % 8];
		
		printf("%c", sold_clothes[i]);
		if (i == N - 1){
			printf("]\n");
		} else{
			printf(", ");
		}
	}

	for(int i = 0; i < argc - 2; i++){
		printf("[PID %d] Launching child to count clothes of type %s\n", getpid(), argv[2 + i]);
		int pid = fork();
		if (pid < 0) {
			printf("[ERROR] Error creating child to count clothes of type %s\n", argv[2 + 1]);
			return -1;
		}
        if(pid > 0) {
			child_pids[n_child] = (int) pid;
			child_types[n_child] = argv[2+i][0];
			n_child++;
			continue;
		}

		int result = 0;

		for(int j = 0; j < N; j++){
			if(sold_clothes[j] == argv[2 + i][0])
				result++;
		}

		exit(result);

	}



	for(int i = 0; i < argc - 2; i++){
		int child_pid = wait(&status);
		if(WIFEXITED(status)){
			
			int pid_index;
			for(int j = 0; j < argc - 2; j++){
				if(child_pids[j] == child_pid){
					pid_index = j;
					break;
				}
			}

            total += status >> 8;

			printf("[PID %d] Child %d of index %d returned:\n\t%d of type %c\n", getpid(), child_pid, pid_index, status >> 8, child_types[pid_index]);
		}else{
			printf("[PID %d] Child %d for couting clothes ended unexpectly with status code: %d\n",getpid(), child_pid, WTERMSIG(status));
		}

	}

    printf("A total of %d items has been purhcased\n", total);
	





}
