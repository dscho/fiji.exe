#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <windows.h>

static __attribute__((noreturn)) void die(const char *message)
{
	fprintf(stderr, "ERROR: %s\n", message);
	exit(1);
}

static void *xmalloc(size_t size)
{
	void *result = malloc(size);
	if (!result) {
		die("Out of memory");
	}
	return result;
}

static int is_64bit(void)
{
	const char *architecture = getenv("PROCESSOR_ARCHITEW6432");

	return architecture && !strcasecmp("amd64", architecture);
}

static char *dos_path(const char *path)
{
	const char *orig = path;
	int size = GetShortPathName(path, NULL, 0);
	char *buffer;

	size = GetShortPathName(path, NULL, 0);
	if (!size) {
		struct stat st;
		if (stat(path, &st)) {
			die("No ImageJ found");
		}
		die("Could not determine DOS name");
	}
	buffer = (char *) xmalloc(size);
	GetShortPathName(path, buffer, size);
	return buffer;
}

int main(int argc, const char *const *argv)
{
	char *slash = strrchr(argv[0], '/'), *back = strrchr(argv[0], '\\');
	char *basename = "ImageJ-win32.exe";
	int size;
	char *prog, **argv2;

	if (slash < back) {
		slash = back;
	}

	if (!slash) {
		prog = strdup(basename);
		if (!prog) {
			die("Out of memory");
		}
		slash = prog;
	}
	else {
		slash++;
		prog = xmalloc((slash - argv[0]) + strlen(basename) + 1);
		memcpy(prog, argv[0], slash - argv[0]);
		slash = prog + (slash - argv[0]);
		strcpy(slash, basename);
	}

	if (is_64bit()) {
		char *thirty_two = strstr(slash, "32");
		if (!thirty_two) {
			die("Could not find '32'");
		}
		thirty_two[0] = '6';
		thirty_two[1] = '4';
	}

	if (slash != prog) {
		prog = dos_path(prog);
	}

	size = sizeof(*argv2) * (argc + 1);
	argv2 = xmalloc(size);
	memcpy(argv2, argv, size);
	argv2[0] = prog;

	if (execvp(prog, (const char *const *) argv2)) {
		die("Error executing ImageJ");
	}
}
