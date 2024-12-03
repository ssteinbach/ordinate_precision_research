# Ordinate Precision Research

## Overview

A series of tests to explore floating point accuracy over large number ranges.

## Falsifiable Hypothesis

Attempting to prove that a rational with an integer component is necessary to
maintain precision over large time scales and under math.

## Methodology

Construct double precision values that fail precision tests thus requiring an
integer rational.

## How to Use

1. Install Zig 0.13.0
2. run:
`zig test inftest.zig`
or
`make all`

To update results:

`make update`

## Results

See: [results.md](results.md)
