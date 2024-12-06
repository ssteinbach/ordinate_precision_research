
const std = @import("std");

const rational_time = @cImport(
    {
        @cInclude("rational_time.c");
    }
);

test "rational tests"
{
    // gcd
    try std.testing.expectEqual(rational_time.gcd32(120, 16), 8);
    try std.testing.expectEqual(rational_time.gcd32(38400, 12000), 2400);
    try std.testing.expectEqual(rational_time.gcd32(11, 7), 1);
    try std.testing.expectEqual(rational_time.gcd32(8, 2), 2);
    try std.testing.expectEqual(rational_time.gcd32(22000, 33000), 11000);
    try std.testing.expectEqual(rational_time.gcd32(12800, 1600), 1600); 

    // lcm32u
    try std.testing.expectEqual(rational_time.lcm32u(8, 2), 8);
    try std.testing.expectEqual(rational_time.lcm32u(11, 7), 77); 
    try std.testing.expectEqual(rational_time.lcm32u(24, 16), 48);

    // lcm32
    try std.testing.expectEqual(rational_time.lcm32(8, 2), 8);
    try std.testing.expectEqual(rational_time.lcm32(11, 7), 77); 
    try std.testing.expectEqual(rational_time.lcm32(24, 16), 48);

    // Rational32 creation
    const a = rational_time.rational32_create(32, 4);
    const b = rational_time.rational32_create(-1, 99);
    const c = rational_time.rational32_create(1, -99);
    const d = rational_time.rational32_create(-11, -7);
    const e = rational_time.rational32_create(38400, 24);
    const f = rational_time.rational32_create(1600, 1);
    const g = rational_time.rational32_create(100 * 24000, 1000);
    const h = rational_time.rational32_create(100 * 24000, 1001);

    try std.testing.expect(a.num == 8 and a.den == 1);
    try std.testing.expect(b.num == -1 and b.den == 99);
    try std.testing.expect(c.num == -1 and c.den == 99);
    try std.testing.expect(d.num == 11 and d.den == 7);
    try std.testing.expect(e.num == 1600 and e.den == 1);

    // normalization
    try std.testing.expect(rational_time.rational32_equal(b,c));
    try std.testing.expect(rational_time.rational32_equal(e,f));
    const n0 = rational_time.rational32_create( 12800, 1600 );
    const n1 = rational_time.rational32_normalize(n0);
    try std.testing.expect(n1.num == 8 and n1.den == 1);

    // equality
    try std.testing.expect(!rational_time.rational32_equal(a, b));
    try std.testing.expect(!rational_time.rational32_equal(c, d));

    // add
    const a1 = rational_time.rational32_add(e, f);
    const a2 = rational_time.rational32_create(3200, 1);
    try std.testing.expect(rational_time.rational32_equal(a1, a2));

    const a3 = rational_time.rational32_create( 12345, 1001 );
    const a4 = rational_time.rational32_create( 12345, 1000 );
    const a5 = rational_time.rational32_create( 24702345, 1001000 );
    const a6 = rational_time.rational32_add(a3, a4);
    try std.testing.expect(rational_time.rational32_equal(a5, a6));

    // less than
    try std.testing.expect( rational_time.rational32_less_than(b, a));
    try std.testing.expect(!rational_time.rational32_less_than(a, b));
    try std.testing.expect(!rational_time.rational32_less_than(e, f));
    try std.testing.expect( rational_time.rational32_less_than(d, a));
    try std.testing.expect(!rational_time.rational32_less_than(a, d));
    try std.testing.expect( rational_time.rational32_less_than(a, f));
    try std.testing.expect(!rational_time.rational32_less_than(f, a));
    try std.testing.expect( rational_time.rational32_less_than(h, g));
    try std.testing.expect(!rational_time.rational32_less_than(g, h));
    try std.testing.expect( rational_time.rational32_less_than_int(a3, 13));
    try std.testing.expect(!rational_time.rational32_less_than_int(a4, 12));
    try std.testing.expect( rational_time.rational32_less_than_int(a4, 13));
    try std.testing.expect(!rational_time.rational32_less_than_int(a6, 24));
    try std.testing.expect( rational_time.rational32_less_than_int(a6, 25));
    // mul
    const k = rational_time.rational32_mul(a, f);
    const l = rational_time.rational32_create(8 * 1600, 1);
    try std.testing.expect(rational_time.rational32_equal(k, l));
    // div
    const m = rational_time.rational32_normalize(rational_time.rational32_div(l, f));
    try std.testing.expect(rational_time.rational32_equal(a, m));
    // time intervals
    const t1 = rational_time.TimeInterval32 {
        .start = rational_time.rational32_create( 0, 1 ),
        .end = rational_time.rational32_create( 1, 1 ),
        .rate = rational_time.rational32_create( 1, 24 )
    };
    const dur1 = rational_time.rational32_create( 1, 1 );
    try std.testing.expect(rational_time.rational32_equal(rational_time.tinterval32_duration(t1), dur1));
    const t2 = rational_time.TimeInterval32 {
        .start = rational_time.rational32_create( 0, 1 ),
        .end = rational_time.rational32_create( 101, 100 ),
        .rate = rational_time.rational32_create( 1, 24 ) };
    const t3 = rational_time.tinterval32_rate_conform(t2);
    try std.testing.expect(rational_time.rational32_equal(rational_time.tinterval32_duration(t3), dur1));
    try std.testing.expect(rational_time.tinterval32_rate_frames(t2) == 24);
}
