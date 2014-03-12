#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int is_64bit(void)
{
	const char *architecture = getenv("PROCESSOR_ARCHITEW6432");

	return architecture && !strcasecmp("amd64", architecture);
}

int main(int argc, const char *const *argv)
{
fprintf(stderr, "%d arguments, 64-bit: %d\n", argc, is_64bit());
	return execvp("echo.exe", argv);
}
