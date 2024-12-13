all:
	zig test -I. -O ReleaseSafe rational_tests.zig
	time zig test -O ReleaseSafe -I. main.zig

update:
	zig test -O ReleaseSafe -I. main.zig >& results.md

int:
	zig test -I. rational_tests.zig
	zig test main.zig -I. --test-filter "rational"
