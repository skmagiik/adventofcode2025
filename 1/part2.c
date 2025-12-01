#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

int main(){
	FILE *f = fopen("input.txt", "r");
	if (!f){
		perror("fopen");
		return 1;
	}

	char *line = NULL;
	size_t len = 0;
	ssize_t read;

	int dial_value = 50;
	uint result = 0;

	while((read = getline(&line, &len, f)) != -1){
		char c = 0x00;
		int num = 0;
		//printf("\nLine: %s", line);
		if (sscanf(line, "%c%d", &c, &num) != 2) {
		    fprintf(stderr, "Failed to parse line: %s", line);
		    return 1;
		}

		int starting_dial_value = dial_value;

		if (c == 'L'){
			dial_value -= num;

			if (starting_dial_value == 0){
				result += num / 100;
				dial_value %= 100;
				if (dial_value < 0){
					dial_value += 100;
				}
			}
			else if (dial_value < 0) {
				result += 1 + (dial_value/-100);
				dial_value %= 100;
				if (dial_value < 0){
					dial_value += 100;
				}
			}
			else if (dial_value == 0){
				result += 1;
			}
		}
		else if (c == 'R'){
			dial_value += num;
			if (dial_value > 99) {
				result += dial_value/100;
				dial_value %= 100;
			}
		}
		else{
			perror("Invalid start of line");
			return 1;
		}
		if (dial_value < 0 || dial_value > 99){
			perror("Invalid dial_value!");
			return 1;
		}
	}
	printf("Result: %d\n", result);

	free(line);
	fclose(f);
	return 0;
};
