all:
	zig test inftest.zig

update:
	zig test inftest.zig >& results.md
