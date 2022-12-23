#include <stdio.h>

extern char **environ;

int main(int argc, char *argv[]) {
    char **ptr = environ;
    int cnt = 0;
    while (*ptr++)
        cnt++;
    printf("Number of command line arguments: %d\n", argc);
    printf("Number of environment variables: %d\n", cnt);

    return 0;
}
