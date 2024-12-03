all:
	time zig test -O ReleaseSafe main.zig

update:
	zig test -O ReleaseSafe main.zig >& results.md
