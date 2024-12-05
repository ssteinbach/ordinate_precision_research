# Ordinate Precision Research

Porcino & Steinbach, Dec 2024

## Abstract

We investigate common assumptions about the representation of time values as an ordinate on a number line, and the impact of representation on computations.

We show the largest values representable, and when the math on various reprsentations stops being exact to various degrees, such as being off by a millisecond, or a half of a frame.

### TL/DR:

See the machine generated results this project generates: [results.md](results.md)

## Introduction

It is common lore that timelines such as those found in editorial NLEs must represent time ordinates with rational integers. In order to prove this we will hit the lore with the rational sledgehammer of the scientific method by constructing a falsifiable hypothesis, H, that a floating point value is sufficient to the purpose. Results to date are provided below which are not sufficient to disprove the hypothesis.

We investigate where the idea comes from that integer rationals are required for time computations, and what tests might we add to falsify the hypothesis H?

The preference for rationals in timelines comes from their guarantee of exactness. Floating-point arithmetic, while flexible and fast, introduces rounding errors that accumulate over time, especially in iterative or mixed operations.

We further demonstrate that integer rational numbers do not in fact mitigate these issues.

The idea that timelines must be represented by rationals likely stems from:

### Exactness in Frame Rates

Media uses frame rates such as 24, 25, 30, 29.97, 23.976 fps, etc., many of which are non-integers or fractions when expressed in seconds. Representing these as rational numbers avoids rounding errors inherent in floating-point approximations.
Rational numbers ensure that every frame aligns perfectly with its time representation, critical when translating between timecodes, frame indices, and audio samples.

### Historical Standards

SMPTE (Society of Motion Picture and Television Engineers) timecodes use fixed frame rates with a denominator (like 1001 for drop-frame formats), aligning naturally with rational arithmetic.
Rational systems predate the widespread use of IEEE floating-point formats and were likely chosen for simplicity and exactness in early implementations.

### Floating Point Pitfalls

Floating-point numbers can accumulate errors in long computations due to rounding, especially in iterative operations like time summation or phase adjustments.
"Half-frame" or sub-frame inaccuracies in calculations (such as summing 23.976 repeatedly) would cause perceptible artifacts like audio drift or misaligned frames.

### Rational Integer Pitfalls

There is a fallacy in the logic promoted popularly. As a point in case, CMTime as used in QuickTime uses rational integers. However, experimentation demonstrates that CMTime, and in fact all robust rational integer implementations must renormalize, particularly in the case of time warps. Mixing two NTSC rates gives as a LCD of 1001 * 1001, and that can compound exponentially with every operation involving mixed rates. A robust implementation like CMTime must invoke a renormalization whenever a maximum bit count is exceeded and thus becomes lossy. This error emerges discretely when bit width capacities are exceeded.

Quilez in Reference 2, in section "Detour - on coprime numbers" illustrates a fundamental inefficiency of rational integer representations, which is that the number of uniquely representable numbers in a rational pair is surprisingly small. A moment's reflection tells us that every pair whose numerator and denominator are equal are equivalent to one; since those numbers all reduce to one, we immediately discover redundancy in the representation. As explained in that paper, 61% of the representable values are unique. Contrast that to a floating point value, where each value is unique.

The low efficiency of the representation and the need for renormalization and its associated lossy behavior is an underappreciated drawback of rational representations, and "rational is perfect" lore seems not to hold up to scrutiny.


## Overview of Method

A series of tests to explore floating point accuracy over large number ranges.

## Falsifiable Hypothesis

Attempting to prove that a rational with an integer component is necessary to
maintain precision over large time scales and under math.

## Methodology

Construct double precision values that fail precision tests thus requiring an
integer rational.

### Accumulation

Test Case: Iteratively sum frame durations (e.g., 1/23.976 seconds) over a large number of iterations and verify alignment against an exact rational baseline.

### Round Trip Precision

Test Case: Cast an NTSC time code repeatedly between float and integer representations and determine when an accuracy threshold is exceeded, or measure how error grows during iteration.

### Variable Frame Rates

Test Case: Demonstrate loss of precision incurred by arbitrary rates

### Phase Alignment

Test Case: Verify sub-frame accuracy over long durations

### Mixed Operations

Test Case: Demonstrate exacerbation of error resulting from mixed mathematical oeprations.

## How to Use

1. Install Zig 0.13.0
2. run:
`zig test -I. main.zig`
or
`make all`

To update results:

`make update`

To run a specific test:

`zig test -I. main.zig --test-filter "name_of_test"`

## Results

See: [results.md](results.md)

## Todo List


* [ ] Specification for the double and its constraints if that is where we land
  (where it should be renormalized, etc)
* [ ] Sin and Cos tests


## Appendix: Data limits of number types

| Type | Bits of Integer Precision | Maximum Integer Value | Max Integer Hours@192KHz | Max Integer Years@192Hz |
|------|---------------------------|-----------------------|--------------------------|-------------------------|
| int32_t | 31 | 2147483647 | 3.10689185 | 0.0003546680195 |
| uint32_t | 32 | 4294967295 | 6.213783702 | 0.0007093360391 |
| double | 53 | 9.0072E+15 | 13031248.92 | 1487.585493 |
| int64_t | 63 | 9.22337E+18 | 13343998896 | 1523287.545 |
| uint64_t | 64 | 1.84467E+19 | 26687997792 | 3046575.09 |


## References

1. Original OpenTimelineIO research on Ordinate types in editorial formats: https://docs.google.com/spreadsheets/d/1JMwBMJuAUEzJFfPHUnI1AbFgIWuIdBkzVEUF80cx6l4/edit?usp=sharing
2. Inigo Quilez Experiments with Rational Number based rendering: https://iquilezles.org/articles/floatingbar/
