# Ordinate Precision Research

Porcino & Steinbach, Dec 2024

--------------------------------------------------------------------------------
## Abstract

We investigate common assumptions about the representation of time values as an ordinate on a number line, and the impact of representation on computations.

We show the largest values representable, and when the math on various reprsentations stops being exact to various degrees, such as being off by a millisecond, or a half of a frame.

--------------------------------------------------------------------------------
### TL/DR

See the machine generated results this project generates: [results.md](results.md)
...or see the compact conclusions from our analysis of the results: [Conclusions](#Conclusions)

--------------------------------------------------------------------------------
## Introduction

It is common lore that timelines such as those found in editorial NLEs must represent time ordinates with rational integers. In order to prove this we will hit the lore with the rational sledgehammer of the scientific method by constructing a falsifiable hypothesis, H, that a floating point value is sufficient to the purpose. Results to date are provided below which are not sufficient to disprove the hypothesis.

We investigate where the idea comes from that integer rationals are required for time computations, and what tests might we add to falsify the hypothesis H?

The preference for rationals in timelines comes from their guarantee of exactness. Floating-point arithmetic, while flexible and fast, introduces rounding errors that accumulate over time, especially in iterative or mixed operations.

We further demonstrate that integer rational numbers do not in fact mitigate these issues.

The idea that timelines must be represented by rationals likely stems from:

### Exactness in Frame Rates

Media uses frame rates such as 24, 25, 30, 30/1.001 (~29.97), 24/1.001 (~23.976) fps, etc., many of which are non-integers or fractions when expressed in seconds. Representing these as rational numbers avoids rounding errors inherent in floating-point approximations.
Rational numbers ensure that every frame aligns perfectly with its time representation, critical when translating between timecodes, frame indices, and audio samples.

### Historical Standards

Society of Motion Picture and Television Engineers SMPTE timecodes[^3] use fixed frame rates with a denominator (like 1001 for drop-frame formats), aligning naturally with rational arithmetic.
Common non-integer rates stem from NTSC[^4] and ATSC[^5] video standards. Rational systems predate the widespread use of IEEE floating-point formats and were likely chosen for simplicity and exactness in early implementations.

Notably, SMPTE ST12-1 2014[^6] states that:
> The results of dividing the integer frame rates by 1.001 do not result in precise decimal numbers, for example, 30/1.001 is 29.970029970029... (to 12 decimals). This is commonly abbreviated as 29.97. In a similar manner, it is common to abbreviate 24/1.001 as 23.98, 48/1.001 as 47.95, and 60/1.001 as 59.94. These abbreviations are used throughout this document. Sufficient precision is necessary in calculations to assure that rounding or truncation operations will not create errors in the end result. This is particularly important when calculating audio sample alignments or when long-term time keeping is required.

For rates defined as 30/1.001 or 24/1.001, system implementers typically use rational numbers 30000/1001 and 24000/1001 which are mathematically equivalent.

### Floating Point Pitfalls

Floating-point numbers can accumulate errors in long computations due to rounding, especially in iterative operations like time summation or phase adjustments. In particular, when the representation of a value exceeds the number of bits available in the mantissa, the exponent must be adjusted, and precision is irreversibly lost.

"Half-frame" or sub-frame inaccuracies in calculations (such as summing 23.976023976023978 repeatedly) would cause perceptible artifacts like audio drift or misaligned frames.

### Rational Integer Pitfalls

There is a fallacy in the logic promoted popularly. As a point in case, CMTime[^7] as used in QuickTime uses rational integers. However, experimentation demonstrates that CMTime, and in fact all robust rational integer implementations must renormalize, particularly in the case of time warps. Mixing two NTSC rates gives as a LCD of 1001 * 1001, and that can compound exponentially with every operation involving mixed rates. A robust implementation like CMTime must invoke a renormalization whenever a maximum bit count is exceeded and thus becomes lossy and irreversible. This error emerges discretely when bit width capacities are exceeded.

This test is demonstrable by the "Integer Rational Sum/Product test" in our results, which shows that after 2145342 (when the multiply rolls over) we lose a bit of precision and the two numbers are now off by one.

Quilez[^2], in section "Detour - on coprime numbers" illustrates a fundamental inefficiency of rational integer representations, which is that the number of uniquely representable numbers in a rational pair is surprisingly small. A moment's reflection tells us that every pair whose numerator and denominator are equal are equivalent to one; since those numbers all reduce to one, we immediately discover redundancy in the representation. As explained in that paper, 61% of the representable values are unique. Contrast that to a floating point value, where each value is unique.

The low efficiency of the representation and the need for renormalization and its associated lossy behavior is an underappreciated drawback of rational representations, and "rational is perfect" lore seems not to hold up to scrutiny.

For specific applications like MIDI timestamps or embedded systems with fixed-rate clocks, rational representations may still be preferable due to hardware constraints.

### Rational Floats

Some systems hedge their bets with a floating point value that is an index over a floating point rate. This representation offers dramatically improved precision in the case where the rate is a repeating fraction. Although this extra precision pays off in fixed rate application, the same pitfalls as occur in rational integers when rates are mixed. When rational integers are mixed, renormalization occurs when bit width is exceeded; similarly when rational floats are mixed, renormalization occurs when mantissa bit width is exceeded and the exponent is increased. As with rational integers the precision loss that occurs then is lossy and irreversible.

### Factorized Integers

Another less common approach in the community is to use what we refer to as a "factorized integer" - an integer that is an index over an implicit rate.  The rate is a large number that is a common factor of a common media rates.  See [^8] and [^9].  These are bounded by both by integer limits, especially for coarser rates and also cannot handle non-integer multiplication or rates whose factors are not present in their rate.  We've included them in the data limits table.

### Sampling and Interpolation

These experiments demonstrate, for a variety of representations, the numeric limits at which a time ordinate unmistakably corresponds to a particular frame at a given framerate. In the regime close to these limits, accurate subsampling and interpolation are not possible due to the fact that the numbers are at the limits of their representation. However, a consequence of the fact that the ordinates are distinguishable at rate means that they can be reversibly be moved to the origin and back again. So, a system that must perform sampling and interpolation may reliably do so by translating a sequence of interest close to the origin and sampling accurately there, as long as it make sense to do the sampling or interpolation in a local frame of reference.

### Continuously Variable Framerate

Continuously variable framerate (CVFR) in modern smartphone cameras operates on a discrete sensor readout clock, typically at a high frequency (e.g., 240 Hz in some configurations). However, the output framerate is not achieved by simple frame skipping; rather, it is dynamically controlled through a combination of exposure time, gain, and readout timing adjustments.

Rather than continuously recording at a fixed high framerate and discarding frames, the system dynamically adjusts exposure duration and readout intervals to achieve a desired output framerate while maintaining synchronization with the rolling shutter scan. This allows for adaptive framerate changes in response to lighting conditions, motion, or energy efficiency considerations.

Frames can be synthesized at the target rate through selective readout, integration, and interpolation techniques, rather than merely dropping frames from a fixed high-rate sequence. This approach optimizes image quality while allowing for framerate flexibility within the constraints of the sensor's rolling shutter and exposure control mechanisms.

Since CVFR systems operate on a discrete readout clock, the precision analysis discussed earlier applies directly. The readout timing and exposure adjustments introduce constraints on exact frame alignment, meaning precision limits are dictated by the granularity of the underlying clock. As with other time representations, cumulative errors may emerge when approximations or truncations occur over extended sequences. Additionally, factors such as sensor clock jitter and temperature-induced timing variations should be considered in long-duration recording scenarios.

--------------------------------------------------------------------------------

## Practical Implications for Timestamping in Mixed Environments

In digital post-production systems that ingest both floating point and rational timecodes, timestamping introduces practical challenges. Mixed environments must reconcile the precision limitations of each format to ensure accurate synchronization and avoid drift over time.

Mixed-format workflows demand robust error handling and reconciliation strategies to ensure that time ordinates remain stable across different computational paradigms.

### Precision Handling

Systems must account for the lossy nature of floating-point arithmetic and the potential for integer rational representations to require renormalization. Differences in rounding strategies between formats can lead to cumulative errors over long durations.

### Interpolation Techniques

When converting between rational and floating-point timestamps, careful interpolation is required to maintain frame alignment. Simple rounding may introduce inconsistencies that manifest as subtle timing artifacts.

### Metadata and Provenance

Maintaining metadata about the original timecode format can help mitigate errors when performing format conversions. Systems that explicitly track whether a timestamp originated from a rational or floating-point source can apply format-specific correction strategies.

--------------------------------------------------------------------------------

## Overview of the Method

A series of tests to explore floating point accuracy over large number ranges.

## Falsifiable Hypothesis

A double precision number is sufficient to maintain precision over large time scales and under math.

## Methodology

Construct double precision values that fail precision tests thus requiring another representation. Show that another representation provides more precision; repeat.

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

--------------------------------------------------------------------------------
## Running the Experiments

1. Install Zig 0.13.0
2. run:
`zig test -Isrc -OReleaseSafe src/main.zig`
or
`make all`

To update results:

`make update`

To run a specific test:

`zig test -Isrc src/main.zig --test-filter "name_of_test"`

--------------------------------------------------------------------------------
## Results

See: [results.md](results.md)

--------------------------------------------------------------------------------
## Conclusions

* We have a number of tests that explore the accuracy of a variety of number
  representations present in audio/video engineering, including integer
  rational, and various bit depths of floating point number.
* Different representations offer different precision limits; this work offers
  insight into which representation to choose for a domain of interest.
* If your system does not require time warps, than integers, or "factorized
  integers"/integer rationals (if you're not mixing rates) are probably
  sufficient.
* For a system that aims to allow warping, audio rates, or NTSC rates,
  a floating point number may be a better choice.
* Floating point numbers do not suffer the same accuracy penalties under
  multiplication that integer rationals do.
* In the limit, integer rational implementations reinvent floating point
  numbers without the benefit of hardware acceleration and deep software
  support.
* For a system that uses a floating-point based number, it is possible to
  compute the accuracy limits imposed by the system and the number bit width.
* For systems that are using integers, conversions to floating point numbers
  are still subject to the limits of floating point accuracy.  If you need
  to synchronize a time value that is past the floating point accuracy limit, it
  doesn't matter if you compute the input with integer accuracy if you still
  need to use a floating point number without sufficient accuracy to convert
  into the other space such as occurs when fetching an audio sample during a
  long running video timeline.

--------------------------------------------------------------------------------
## Todo List


* [ ] Specification for the double and its constraints if that is where we land
  (where it should be renormalized, etc)
* [ ] worth noting the difference between f32->f64->f128 and integer rational
  i32->i64 etc.
* [ ] Fold other references from [^1] into the document.
* [ ] Verify the sampling hypothesis that numbers near the limit may be
  reversibly brought near the origin and put back again


--------------------------------------------------------------------------------
## Appendix: Data limits of number types

| Type | Bits of Integer Precision | Maximum Integer Value | Max Integer Hours@192KHz (~5.2µs) | Max Integer Years@192Hz (~5.2µs) |
|------|---------------------------|-----------------------|--------------------------|-------------------------|
| int32_t | 31 | 2147483647 | 3.10689185 | 0.0003546680195 |
| uint32_t | 32 | 4294967295 | 6.213783702 | 0.0007093360391 |
| double | 53 | 9.0072E+15 | 13031248.92 | 1487.585493 |
| int64_t | 63 | 9.22337E+18 | 13343998896 | 1523287.545 |
| uint64_t | 64 | 1.84467E+19 | 26687997792 | 3046575.09 |


--------------------------------------------------------------------------------
## References

[^1]: Original OpenTimelineIO research on Ordinate types in editorial formats: https://docs.google.com/spreadsheets/d/1JMwBMJuAUEzJFfPHUnI1AbFgIWuIdBkzVEUF80cx6l4/edit?usp=sharing
[^2]: Inigo Quilez Experiments with Rational Number based rendering: https://iquilezles.org/articles/floatingbar/
[^3]: SMPTE timecode: https://en.wikipedia.org/wiki/SMPTE_timecode
[^4]: NTSC video standard: https://en.wikipedia.org/wiki/NTSC
[^5]: ATSC video standard: https://en.wikipedia.org/wiki/ATSC_standards
[^6]: SMPTE timecode specification: https://pub.smpte.org/pub/st12-1/st0012-1-2014.pdf
[^7]: Apple CoreMedia CMTime: https://developer.apple.com/documentation/coremedia/cmtime-api
[^8]: Ticks: https://iquilezles.org/articles/ticks/
[^9]: Flicks: https://github.com/facebookarchive/Flicks
