all:
	time zig test -O ReleaseSafe -I. main.zig

update:
	zig test -O ReleaseSafe -I. main.zig >& results.md

int:
	zig test main.zig -I. --test-filter "rational"
