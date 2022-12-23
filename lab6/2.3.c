#include <stdio.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    int pid = fork();
    for (int i = 0; i < 10; ++i)
        if (pid)
            fork();
    sleep(5);

    return 0;
}
