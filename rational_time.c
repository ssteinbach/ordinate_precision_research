
// clang -g rational_time.c -std=c18

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
/*
 * Rational32
 *
 * a 32 bit signed rational number
 *
 * A denominator of zero indicates infinity
 */

typedef struct {
    int32_t num;
    uint32_t den;
} Rational32;

/*
 * TimeInterval32
 *
 * a rate of infinity indicates that the interval is continuous
 */

typedef struct {
    Rational32 start;
    Rational32 end;
    Rational32 rate;
} TimeInterval32;




// Stein's algorithm

uint32_t gcd32(uint32_t u, uint32_t v) 
{
    uint32_t shl = 0;
    if (u == 0) return v;
    if (v == 0) return u;
    if (u == v) return u;

    while ((u != 0) && (v != 0) && (u != v)) {
        bool eu = (u&1) == 0;
        bool ev = (v&1) == 0;
        if (eu && ev) {
            shl += 1;
            v >>= 1;
            u >>= 1;
        }
        else if (eu && !ev) { u >>= 1; }
        else if (!eu && ev) { v >>= 1; }
        else if (u > v)     { u = (u - v) >> 1; }
        else {
            uint32_t temp = u;
            u = (v - u ) >> 1;
            v = temp;
        }
    }
    if (u == 0) return v << shl;
    return u << shl;
}

uint64_t gcd64(uint64_t u, uint64_t v) 
{
    uint64_t shl = 0;
    if (u == 0) return v;
    if (v == 0) return u;
    if (u == v) return u;

    while ((u != 0) && (v != 0) && (u != v)) {
        bool eu = (u&1) == 0;
        bool ev = (v&1) == 0;
        if (eu && ev) {
            shl += 1;
            v >>= 1;
            u >>= 1;
        }
        else if (eu && !ev) { u >>= 1; }
        else if (!eu && ev) { v >>= 1; }
        else if (u > v)     { u = (u - v) >> 1; }
        else {
            uint32_t temp = u;
            u = (v - u ) >> 1;
            v = temp;
        }
    }
    if (u == 0) return v << shl;
    return u << shl;
}

int32_t lcm32(int32_t u_, int32_t v_) 
{
    // 
    int32_t u = u_;
    int32_t v = v_;
    if (v < 0) {
        u = -u;
        v = -v;
    }
    int32_t sgn = (u < 0) ? -1 : 1;
    uint64_t uu = (u < 0) ? -u : u;
    uint64_t vu = v;
    uint64_t div = (uu * vu) / gcd32(uu, vu);
    return sgn * (int32_t) div;
}

uint32_t lcm32u(uint32_t u, uint32_t v) 
{
    uint64_t uu = u;
    uint64_t vu = v;
    return (uint32_t)( (uu * vu) / gcd32(u, v));
}

int32_t rational32_sign(Rational32 r)
{
    return r.num > 0 ? 1 : -1;
}

Rational32 rational32_abs(Rational32 r)
{
    return (Rational32) { r.num > 0 ? r.num : -r.num, r.den };
}

Rational32 rational32_create(int32_t n_, int32_t d_)
{
    if (d_ == 0 || n_ == 0)
        return (Rational32) { n_, d_ };
    int32_t n = n_;
    int32_t d = d_;
    if (d_ < 0) {
        n = -n;
        d = -d;
    }
    int32_t sign = (n < 0) ? -1 : 1;
    uint32_t nu = (n < 0) ? -n : n;
    uint32_t du = d;
    uint32_t div = gcd32(nu, du);
    return (Rational32) { 
        sign * (int32_t) (nu / div), du / div };
}

bool rational32_is_inf(Rational32 r)
{
    return r.den == 0;
}

Rational32 rational32_normalize(Rational32 r)
{
    if (r.num == 0 || r.num == 1 || r.den == 1 || r.den == 0) 
        return r;
    if (r.num == r.den)
        return (Rational32) { 1, 1 };
    uint32_t n = r.num < 0 ? -r.num : r.num;
    uint32_t denom = gcd32(n, r.den);
    return (Rational32) { 
        r.num / denom, r.den / denom };
}

Rational32 rational64_normalize_to_32(int64_t num, uint64_t den)
{
    if (num == 0 || num == 1 || den == 1 || den == 0) 
        return (Rational32) { (int32_t) num, (uint32_t) den };
    if (num == den)
        return (Rational32) { 1, 1 };
    int32_t sign = num < 0 ? -1 : 1;
    uint64_t n = num < 0 ? -num : num;
    uint64_t denom = gcd64(n, den);
    uint64_t rn = n / denom;
    uint64_t rd = den / denom;

    // check if the result fits in 32 bits
    if ((rn < 0x7FFFFFFF) && (rd < 0xFFFFFFFF)) {
        return (Rational32) { 
            sign * (int32_t) rn, (uint32_t) rd };
    }

    //printf("Overflow %x %x\n", rn, rd);
    // shift rn and rd to the right to make them fit in 32 bits
    while ((rn > 0x7FFFFFFF) || (rd > 0xFFFFFFFF)) {
        rn >>= 1;
        rd >>= 1;
        //printf("         %x %x\n", rn, rd);
    }
    //printf("Result %x %x\n", sign * (int32_t) rn, (uint32_t) rd);
    //printf(" in int %f\n", (int32_t) rn);
    //printf(" in float %f\n", (float) sign * (float) rn / (float) rd);
    return (Rational32) { 
        sign * (int32_t) rn, (uint32_t) rd };
}

Rational32 rational32_force_den(Rational32 r, uint32_t den)
{
    return (Rational32) {
        (r.num * den) / r.den };
}

Rational32 rational32_add(Rational32 lh, Rational32 rh)
{
    int32_t lhsign = lh.num < 0 ? -1 : 1;
    uint64_t n0 = lhsign < 0 ? -lh.num : lh.num;
    int32_t rhsign = rh.num < 0 ? -1 : 1;
    uint64_t n1 = rhsign < 0 ? -rh.num : rh.num;

    const uint64_t d0 = lh.den;
    const uint64_t d1 = rh.den;
    
    const int64_t num = lhsign * rhsign * (n0 * d1 + d0 * n1);
    const uint64_t den = d0 * d1;

    return rational64_normalize_to_32(num, den);
}

Rational32 rational32_negate(Rational32 r)
{
    return (Rational32) { -r.num, r.den };
}

Rational32 rational32_sub(Rational32 lh, Rational32 rh)
{
    return rational32_add(lh, rational32_negate(rh));
}

Rational32 rational32_mul(Rational32 lh, Rational32 rh)
{
    int32_t sign = rational32_sign(lh) * rational32_sign(rh);
    Rational32 lhu = rational32_abs(lh);
    Rational32 rhu = rational32_abs(rh);
    uint64_t g1 = gcd32(lhu.num, lhu.den);
    uint64_t g2 = gcd32(rhu.num, rhu.den);
    int64_t rn = sign * ((lhu.num / g1) * rhu.num) / g2;
    uint64_t rd = ((lhu.den / g2) * rhu.den) / g1;
    return rational64_normalize_to_32( rn, rd );
}

Rational32 rational32_inverse(Rational32 r)
{
    return (Rational32) { r.den, r.num };
}

Rational32 rational32_div(Rational32 lh, Rational32 rh)
{
    return rational32_mul(lh, rational32_inverse(rh));
}

bool rational32_equal(Rational32 lh, Rational32 rh)
{
    Rational32 a = rational32_normalize(lh);
    Rational32 b = rational32_normalize(rh);
    return a.num == b.num && a.den == b.den;
}

// reference:
// operator < in https://www.boost.org/doc/libs/1_55_0/boost/rational.hpp
bool rational32_less_than(Rational32 lh, Rational32 rh)
{
    if (lh.den < 0 || rh.den < 0)
        return false;   // not comparable

    int32_t n_l = lh.num;
    int32_t d_l = lh.den;
    int32_t q_l = n_l / d_l;
    int32_t r_l = n_l % d_l;
    int32_t n_r = rh.num;
    int32_t d_r = rh.den;
    int32_t q_r = n_r / d_r;
    int32_t r_r = n_r % d_r;
    
    // normalize non-negative moduli
    while (r_l < 0) { r_l += d_l; --q_l; }
    while (r_r < 0) { r_r += d_r; --q_r; }

    uint8_t reversed = 0;
    // compare continued fraction components
    while (true) {
        // quotients of the current cycle are continued-fraction components.
        // comparing these is comparing their sequences, stop at the first
        // difference
        if (q_l != q_r) {
            return reversed? q_l > q_r : q_l < q_r;
        }

        reversed ^= 1;
        if (r_l == 0 || r_r == 0) {
            // expansion has ended
            break;
        }

        n_l = d_l; d_l = r_l;
        q_l = n_l / d_l;
        r_l = n_l % d_l;

        n_r = d_r; d_r = r_r;
        q_r = n_r / d_r;
        r_r = n_r % d_r;
    }

    if (r_l == r_r) {
        // previous loop broke on zero remainder; both zeroes means
        // the sequence is over and the values are equal.
        return false;
    }

    // one of the remainders is zero, so the other value is lesser
    return (r_r != 0) != (reversed == 1);
}

bool rational32_less_than_int(Rational32 r32, int i)
{
    if (r32.den <= 0)
        return false;   // not comparable

    int32_t q = r32.num / r32.den;
    int32_t r = r32.num % r32.den;
    while (r < 0)  { r += r32.den; --q; }
    
    // remainder pushed the quotient down, so it's only necessary to
    // compare the quotient.
    return q < i;
}

int32_t rational32_floor(Rational32 a)
{
    return a.num / a.den;
}

bool tinterval32_well_formed(TimeInterval32 a)
{
    return rational32_less_than(a.start, a.end);
}

/* Allen's Interval algebra
 *
 * The interval predicates operate on the bounds of the interval.
 * The rate is not considered.
 */

// a precedes b
// every point in a is strictly before every point in b
//
//  [   a    )    [  b    )
//
bool tinterval32_precedes(TimeInterval32 a, TimeInterval32 b)
{
    return tinterval32_well_formed(a) && tinterval32_well_formed(b) &&
           rational32_less_than(a.end, b.start);
}

// a meets b
// a and b together perfectly span the interval they cover
//
//   [   a    [    b    )
//
bool tinterval32_meets(TimeInterval32 a, TimeInterval32 b)
{
    return tinterval32_well_formed(a) && tinterval32_well_formed(b) &&
           rational32_equal(a.end, b.start);
}

// a overlaps b
// a starts before b, and ends within b
//
//     [   a          )
//              [  b           )
bool tinterval32_overlaps(TimeInterval32 a, TimeInterval32 b)
{
    return tinterval32_well_formed(a) && tinterval32_well_formed(b) &&
           rational32_less_than(a.start, b.start) &&
           rational32_less_than(b.start, a.end);
}

// a starts b
// a and b share a start, a ends within b
//
//    [ a      )
//    [ b          )
//
bool tinterval32_starts(TimeInterval32 a, TimeInterval32 b)
{
    return tinterval32_well_formed(a) && tinterval32_well_formed(b) &&
           rational32_equal(a.start, b.start) &&
           rational32_less_than(a.end, b.end);
}

// a within b
// a strictly within b
//
//        [   a       )
//     [  b              )
//
bool tinterval32_during(TimeInterval32 a, TimeInterval32 b)
{
    return tinterval32_well_formed(a) && tinterval32_well_formed(b) &&
           rational32_less_than(b.start, a.start) &&
           rational32_less_than(a.end, b.end);
}


// a end b
// a starts after b, and ends with b
//
//        [   a       )
//     [  b           )
//
bool tinterval32_ends(TimeInterval32 a, TimeInterval32 b)
{
    return tinterval32_well_formed(a) && tinterval32_well_formed(b) &&
           rational32_less_than(b.start, a.start) &&
           rational32_equal(a.end, b.end);
}

// a equal b
// a strictly covers b
//
//     [   a       )
//     [  b        )
//
bool tinterval32_equal(TimeInterval32 a, TimeInterval32 b)
{
    return tinterval32_well_formed(a) && tinterval32_well_formed(b) &&
           rational32_equal(a.start, b.start) &&
           rational32_equal(a.end, b.end);
}


// a disjoint b
// a precedes b or vice versa
//
//     [   a       )
//                        [  b        )
//
bool tinterval32_disjoint(TimeInterval32 a, TimeInterval32 b)
{
    return tinterval32_precedes(a, b) ||
           tinterval32_precedes(b, a);
}

// a subset b
// a starts, ends, within, or equals b
//
//     [   a       )
//     [  b         )
//
bool tinterval32_subset(TimeInterval32 a, TimeInterval32 b)
{
    return 
        (rational32_less_than(b.start, a.start) || 
         rational32_equal(a.start, a.end)) && 
        (rational32_less_than(a.end, b.end) || 
         rational32_equal(a.end, b.end));
}


// a within b
// a starts, ends, during, but not equal b
//
//     [   a       )
//     [  b         )
//
bool tinterval32_within(TimeInterval32 a, TimeInterval32 b)
{
    return !tinterval32_equal(a, b) && tinterval32_subset(a, b);
}

// duration
Rational32 tinterval32_duration(TimeInterval32 a)
{
    return rational32_sub(a.end, a.start);
}

// conform
//
// return: The largest time interval quantized at rate, that fits within a
TimeInterval32 tinterval32_rate_conform(TimeInterval32 a)
{
    /* algorithm:
    float dur = end - start;       // full duration
    float frames = dur / rate;     // frames
    float iframes = floor(frames); // largest number of frames within frames
    float qdur = iframes * rate;   // truncated duration
    return { start, start + qdur, rate };  // result
    */
    Rational32 dur =  tinterval32_duration(a);
    Rational32 frames =  rational32_div(dur, a.rate);
    Rational32 iframes = { rational32_floor(frames), 1 };
    Rational32 qdur =  rational32_mul(iframes, a.rate);
    return (TimeInterval32) {
        a.start, rational32_add(a.start, qdur), a.rate };
}

// conform
//
// return: The largest time interval quantized at rate, that fits within a
int32_t tinterval32_rate_frames(TimeInterval32 a)
{
    /* algorithm:
    float dur = end - start;       // full duration
    float frames = dur / rate;     // frames
    float iframes = floor(frames); // largest number of frames within frames
    */
    Rational32 dur =  tinterval32_duration(a);
    Rational32 frames =  rational32_div(dur, a.rate);
    return rational32_floor(frames);
}

#ifdef HAVE_MUNIT
#include <stdio.h>
#include "munit.h"
#include "munit.c"

void rational32_tests()
{
    // gcd
    munit_assert(gcd32(120, 16) == 8);
    munit_assert(gcd32(38400, 12000) == 2400);
    munit_assert(gcd32(11, 7) == 1);
    munit_assert(gcd32(8, 2) == 2);
    munit_assert(gcd32(22000, 33000) == 11000);
    munit_assert(gcd32(12800, 1600) == 1600); 

    // lcm32u
    munit_assert(lcm32u(8, 2) == 8);
    munit_assert(lcm32u(11, 7) == 77); 
    munit_assert(lcm32u(24, 16) == 48);

    // lcm32
    munit_assert(lcm32(8, 2) == 8);
    munit_assert(lcm32(11, 7) == 77); 
    munit_assert(lcm32(24, 16) == 48);

    // Rational32 creation
    Rational32 a = rational32_create(32, 4);
    Rational32 b = rational32_create(-1, 99);
    Rational32 c = rational32_create(1, -99);
    Rational32 d = rational32_create(-11, -7);
    Rational32 e = rational32_create(38400, 24);
    Rational32 f = rational32_create(1600, 1);
    Rational32 g = rational32_create(100 * 24000, 1000);
    Rational32 h = rational32_create(100 * 24000, 1001);

    munit_assert(a.num == 8 && a.den == 1);
    munit_assert(b.num == -1 && b.den == 99);
    munit_assert(c.num == -1 && c.den == 99);
    munit_assert(d.num == 11 && d.den == 7);
    munit_assert(e.num == 1600 && e.den == 1);

    #define norm(a) rational32_normalize((a))
    #define eq(a,b) rational32_equal((a), (b))
    #define lt(a, b) rational32_less_than((a), (b))
    #define lti(a, b) rational32_less_than_int((a), (b))
    #define add(a, b) rational32_add((a), (b))
    #define mul(a, b) rational32_mul((a), (b))
    #define div(a, b) rational32_div((a), (b))

    // normalization
    munit_assert(eq(b,c));
    munit_assert(eq(e,f));
    Rational32 n0 = { 12800, 1600 };
    Rational32 n1 = norm(n0);
    munit_assert(n1.num == 8 && n1.den == 1);

    // equality
    munit_assert(!eq(a, b));
    munit_assert(!eq(c, d));

    // add
    Rational32 a1 = add(e, f);
    Rational32 a2 = rational32_create(3200, 1);
    munit_assert(eq(a1, a2));

    Rational32 a3 = { 12345, 1001 };
    Rational32 a4 = { 12345, 1000 };
    Rational32 a5 = { 24702345, 1001000 };
    Rational32 a6 = add(a3, a4);
    munit_assert(eq(a5, a6));

    // less than
    munit_assert( lt(b, a));
    munit_assert(!lt(a, b));
    munit_assert(!lt(e, f));
    munit_assert( lt(d, a));
    munit_assert(!lt(a, d));
    munit_assert( lt(a, f));
    munit_assert(!lt(f, a));
    munit_assert( lt(h, g));
    munit_assert(!lt(g, h));
    munit_assert( lti(a3, 13));
    munit_assert(!lti(a4, 12));
    munit_assert( lti(a4, 13));
    munit_assert(!lti(a6, 24));
    munit_assert( lti(a6, 25));
   // mul
    Rational32 k = mul(a, f);
    Rational32 l = rational32_create(8 * 1600, 1);
    munit_assert(eq(k, l));
    // div
    Rational32 m = norm(div(l, f));
    munit_assert(eq(a, m));
    // time intervals
    TimeInterval32 t1 = (TimeInterval32) {
        (Rational32) { 0, 1 },
        (Rational32) { 1, 1 },
        (Rational32) { 1, 24 } };
    Rational32 dur1 = { 1, 1 };
    munit_assert(eq(tinterval32_duration(t1), dur1));
    TimeInterval32 t2 = (TimeInterval32) {
        (Rational32) { 0, 1 },
        (Rational32) { 101, 100 },
        (Rational32) { 1, 24 } };
    TimeInterval32 t3 = tinterval32_rate_conform(t2);
    munit_assert(eq(tinterval32_duration(t3), dur1));
    munit_assert(tinterval32_rate_frames(t2) == 24);
 }

int main()
{
    rational32_tests();
    return 0;
}
#endif // HAVE_MUNIT
