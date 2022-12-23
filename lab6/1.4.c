#include <stdio.h>
#include <stdlib.h>

extern char **environ;

int main(int argc, char *argv[]) {
    char **ptr;
    for (ptr = environ; *ptr && ptr - environ < atoi(argv[1]); ptr++)
        printf("%s\n", *ptr);

    return 0;
}
