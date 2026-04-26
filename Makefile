# Makefile for ordinate_precision_research
#
# Makes it convienent to generate and run program to produce results.md

all: update
	cat results.md

update:
	zig build run --release=fast -- results.md

.PHONY: update all
