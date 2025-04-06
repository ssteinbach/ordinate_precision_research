# repo was originally built around zig test and not zig build
#
# @TODO: rejigger around zig build instead of zig test

all:
	zig test -Isrc -O ReleaseSafe src/rational_tests.zig
	time zig test -O ReleaseSafe -Isrc src/main.zig

update:
	zig test -O ReleaseSafe -Isrc src/main.zig >& results.md

int:
	zig test -Isrc src/rational_tests.zig
	zig test src/main.zig -Isrc --test-filter "rational"

build_test:
	zig build test
