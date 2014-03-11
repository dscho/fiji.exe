#!/bin/sh

# This script makes a polyglot PE based on the idea presented in
#
# https://thunked.org/programming/it-s-a-pe-no-it-s-an-elf-t222.html
#
# Briefly, the idea is to abuse the DOS header of every PE (it must start
# with 'MZ' and the next 57 bytes or so are there only for backwards
# compatibility that is only relevant when calling the executables on DOS) to
# make the program also a shell script that simply skips the Windows executable.
#
# Windows will execute the result as PE32 progam, all other platforms will
# execute it as a shell script.

die () {
	echo "$*" >&2
	exit 1
}

cd "$(pwd)" ||
die Could not determine current directory

gcc -s -o 0.exe fiji.c ||
die Could not compile fiji.c

basename="${0##*/}"

offsetof () {
	grep -b "$1" "$basename" |
	sed 's/:.*//'
}

filesize () {
	stat -c %s fiji.exe
}

printf 'MZ= eval "$(%s 2> /dev/null)"; exit\n' \
	"dd if=\"\$0\" skip=1 bs=$(stat -c %s 0.exe)" > fiji.exe &&
dd if=0.exe bs=$(filesize) skip=1 >> fiji.exe &&
dd if="$basename" ibs=$((7+$(offsetof '^exit 0$'))) skip=1 >> fiji.exe ||
die Could not put together the hybrid executable

rm 0.exe ||
die Could not delete intermediate file

exit 0

echo "args: $*" >&2
