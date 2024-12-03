all:
	time zig test -O ReleaseSafe inftest.zig

update:
	zig test -O ReleaseSafe inftest.zig >& results.md
