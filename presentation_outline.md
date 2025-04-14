# Presentation Outline

* Intro
    * Common wisdom on editorial apps is to use integer rationals, we ask: can we prove that?
        * answer: No!
    * If we start from a uniformely sampled file, like a sequence of EXR frames, an integer index makes sense (+ another pair of integers for labelling the sampling rate metric)
    * If there are two uniformly sampled spaces that may require transformations from one to the other, then theoretically an integer rational makes sense (so, a picture track and audio track for example)
        * ...with only addition and subtraction to do the transformation
        * ...otherwise the problems we'll talk about in this presentation emerge
    * Digital computers can only directly represent integers
        * IEEE 754 floating point numbers and big nums are fancy ways of using integers to create numbers that are not integers
        * IEEE 754 specifically can be thought of as an integer rational with a base that is a power of two
        * If you invent your own integer class, you're building an approximation of/converge on IEEE 754... using an arbitrary base rather than a power of two
        * digital computers really like powers of two... 
        * at this point IEEE 754 is well supported and hardware accelerated on all production hardware
        * that is to say, IEEE 754 is likely a local maxima for the representation of fixed bit-width non integer numbers on digital computers
        * to put that another way, if you have a fixed bit budget (ie 128 bits), and want a number that can operate in continuous math:
            * spending the bits on an IEEE 754 is the most bit-effecient, correct, and performance optimal choice (and we'll demonstrate that in this presentation)
        * Integer rationals are great for labelling frames, but if you need to do math, use floating point numbers
        * We also show the limits of numerical accuracy of floating point numbers with respect to things you want to do on a timeline (really, for a continuous number line, but we'll use the example of a timeline)
* Methodology
    * Emprical explorations
        * Sum/Product Test
        * Sine Test
        * NTSC Rate Degredation Test
        * Numerical limits of various types 
    * Explorations of numerical types
        * Phase Ordinates
        * Dual Numbers
        * Integer Rationals
        * Floating point
* Theoretical Analysis
    * Renormalization of IEEE 754 vs Integer Rationals
    * Bit-effeciency of Integer Rationals
    * Convergence of "rational-like" types on IEEE 754
    * Implications for Sampling frameworks (accuracy lost cannot be regained - ie rehoming cannot resolve transformations on really large timelines)
        * importance of the frame of reference - the computer graphics trick of rehoming/originating a shot cannot work if a value needs to be continuous over the entire timeline
* Conclusions
    * integer-based Rational numbers converge on IEEE 754
    * if you need continuous math, use floats.  if you need more accuracy, use bigger floats
    * understand the limits you want to support so you can decide how big of a float you need

