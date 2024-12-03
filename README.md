# Ordinate Precision Research

Porcino & Steinbach, Dec 2024

## Introduction

It is common lore that timelines such as found in editorial NLEs must be represented by rational integers. In order to prove this we are constructing a falsifiable hypothesis, H, that a floating point value is sufficient to the purpose. Results to date are provided below which are not sufficient to disprove the hypothesis.

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

The need for renormalization and its associated lossy behavior is an underappreciated drawback of rational representations, and "rational is perfect" lore may not hold up to scrutiny.

Using logarithms we can quickly demonstrate how prevalent the renormalization problem is. Using a denominator of 1001 to stand in for NTSC rates, we can immediately observe that by design values, cannot be renormalized due to a lack of common factors. 

30000/1001 * 24000/1001 = 720,000,000 / 1,002,001

The Greatest Common Divisor of 720,000,000 and 1,002,001 is 1, the fraction is in its simplest form. We already need 30 bits for the numerator and 20 for the denominator. Using base 2 logarithms, we can quickly show that overflow occurs almost immediately for NTSC rates.

log2(bits) = log2(numerator) + k * log2(denominator)

overflow occurs when log2(bits) > integer bits. For 32 bits, k is roughly 2.2, so overflow and therefore renormalization occurs after two multiplications.

Doubling the number of bits only increases the overflow threshold by a signle step or so, so big integers are not a panacea. This demonstrates a severe limitation of integer rationals in a mixed frame rate environment, to the degree that the vaunted exactness of integer rationals cannot be demonstrated in use cases that matter to us.

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
`zig test inftest.zig`
or
`make all`

To update results:

`make update`

## Results

See: [results.md](results.md)
