#include <stdio.h>
#include <unistd.h>

int main(int argc, const char *const *argv)
{
fprintf(stderr, "%d arguments\n", argc);
	return execvp("echo.exe", argv);
}
