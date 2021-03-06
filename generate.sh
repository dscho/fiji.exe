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

cut_script="sed '1,/^EOFEOFEOF/d'"

test --test-sh != "$1" || {
	argv0="$0"
	shift
	eval "$(eval "$cut_script" < "$argv0")"
	exit
}

test 0 = $# ||
die "Usage: $0 [--test-sh [<arg>...]]"

uname="$(uname)"
test "a${uname#MINGW}" != "a$uname" ||
die "Need to run on Windows, except with --test-sh"

cd "$(pwd)" ||
die Could not determine current directory

gcc -s -o 0.exe fiji.c ||
die Could not compile fiji.c

launcher=ImageJ-win32.exe
test -x $launcher ||
launcher=ImageJ-win64.exe
if test -x $launcher
then
	if test -f fiji.ico
	then
		./$launcher --set-icon 0.exe fiji.ico
	else
		echo "No fiji.ico found; *not* setting the icon" >&2
	fi
else
	echo "No ImageJ launcher found; *not* setting the icon" >&2
fi

basename="${0##*/}"

offsetof () {
	grep -b "$1" "$basename" |
	sed 's/:.*//'
}

filesize () {
	stat -c %s fiji.exe
}

printf 'MZ= eval "$(%s < "$0")"; exit\n' "$cut_script" > fiji.exe &&
dd if=0.exe bs=$(filesize) skip=1 >> fiji.exe &&
dd if="$basename" ibs=$((6+$(offsetof '^exit 0$'))) skip=1 >> fiji.exe ||
die Could not put together the hybrid executable

rm 0.exe ||
die Could not delete intermediate file

exit 0
EOFEOFEOF

# When found in PATH, "$0" will have the absolute path on Linux & MacOSX
ij_dir="$(dirname "$0")"

uname_s="$(uname -s)"
uname_m="$(uname -m)"

case "$uname_m,$uname_s" in
i386,Linux)
	launcher=ImageJ-linux32;;
x86_64,Linux)
	launcher=ImageJ-linux64;;
*,Darwin)
	launcher=Contents/MacOS/ImageJ-tiger;;
*)
	die "Cannot execute ImageJ on $uname_s ($uname_m) yet";;
esac

test -x "$ij_dir"/$launcher ||
die "Did not find $launcher in $ij_dir"

exec "$ij_dir"/$launcher "$@"
