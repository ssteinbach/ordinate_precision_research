//! A series of tests to explore floating point accuracy over large number
//! ranges
//!
//! Falsifiable Hypothesis:
//!
//! Attempting to prove that a rational with an integer component is necessary
//! to maintain precision over large time scales and under math.
//!
//! Methodology:
//!
//! Construct double precision values that fail precision tests thus requiring
//! an integer rational.
//!

const std = @import("std");

// @TODO: add a readme that describes this, has links to the old spreadsheet
//        and can serve as the starting point for a spec/document
// @TODO: reintroduce the sin and cos blowing up test
// @TODO: solicit feedback from folks in the community
// @TODO: Write a specification/document that describes how to use either the
//        floating point number or the integer rational, where you need to
//        renormalize, etc. to maintain precision behavior.

const TABLE_HEADER_FP_SUM_PRODUCT = (
\\ 
\\ | rate | iterations | tolerance | wall clock time |
\\ |------|------------|-----------|-----------------|
);

test "Floating point product vs Sum Test"
{
    std.debug.print(
        "\n\n# Ordinate Precision Exploration\n",
        .{}
    );

    std.debug.print(
        "\n\n## Float Type Exploration\nReports how many iterations before "
        ++ "the sum is not equal to the product by more than half a frame\n",
        .{}
    );

     // if (true) {
     //     // this test is good but takes a while, switching to other tests
     //     return error.SkipZigTest;
     // }

    inline for (
        &.{
            f32, 
            // f64,
            // f128,
        }
    ) |T|
    {
        std.debug.print(
            "\n### Type: {s}\n{s}\n",
            .{ @typeName(T), TABLE_HEADER_FP_SUM_PRODUCT},
        );

        for (
            &[_]T{ 
                24.0,
                24.0 * 1000.0 / 1001.0,
                120,
                48000.0,
                192000.0,
            }
        ) |rate|
        {
            for (
                &[_]T{
                    1.0 / (rate*2),
                    5e-4,
                }
            ) |MIN_TOLERANCE|
            {
                // ms accuracy
                // const MIN_TOLERANCE : T = 1.0 / (rate*2);

                // const MIN_TOLERANCE : T = 4.9e-5;

                const start : T = 0;
                const increment : T = @floatCast(1.0 / rate);
                var current : T = start;
                var iter : usize = 0;
                var tolerance: T = MIN_TOLERANCE;

                while (tolerance < 0.1) 
                    : ({iter += 1 ; current += increment;})
                {
                    if (
                        std.math.approxEqAbs(
                            T,
                            start + @as(T, @floatFromInt(iter)) * increment,
                            current,
                            tolerance
                        ) == false
                    ) 
                    {
                        var buf : [1024]u8 = undefined;
                        const time_str = try time_string(
                            &buf,
                            current,
                        );

                        std.debug.print(
                            " | {d} | {d} | {d} | {s} |\n",
                            .{ rate, iter, tolerance, time_str }
                        );
                        tolerance *= 10;
                        break;
                    }
                }
            }
        }
    }
    std.debug.print("\n",.{});
}

fn time_string(
    buf: []u8,
    val: anytype,
) ![]u8
{
    return (
        if (val < 60)
            try std.fmt.bufPrint(buf, "{d:0.3}s", .{ val })
        else if (val < 60 * 60)
            try std.fmt.bufPrint(buf, "{d:0.3}m", .{ val / 60 })
        else if (val < 60 * 60 * 24)
            try std.fmt.bufPrint(buf, "{d:0.3}h", .{ val / (60 * 60) })
        else 
            try std.fmt.bufPrint(buf, "{d:0.3}d", .{ val / (60 * 60 * 24) })
    );
}


const TABLE_HEADER_TIME_TO_FRAME_N = (
\\ 
\\ | rate | iter | Failure | failure frame | expected | measured |
\\ |------|------|---------|---------------|----------|----------|
);


test "Floating point division to integer test"
{
    std.debug.print(
        "\n\n## Time to Frame Number Test\n"
        ++ "Measures if the correct integer frame number and phase offset can"
        ++ "be recovered from a large time value.\n"
        ,
        .{}
    );

    inline for ( 
        &.{
            // f16,
            f32, 
            f64,
        }
    ) |T|
    {
        std.debug.print(
            "\n### Type: {s}\n{s}\n",
            .{ @typeName(T), TABLE_HEADER_TIME_TO_FRAME_N}
        );

        for (
            &[_]T{
                24.0,
                24.0*1000.0/1001.0,
                25.0,
                30.0*1000.0/1001.0,
                120,
                48000,
                192000,
            }
        ) |rate|
        {
            var input_t:T = rate;
            var expected_t:u128 = 1.0;

            var iters:usize = 0;
            const mult = 10; 
            while (true)
                : ({ input_t *= mult; expected_t *= mult; iters+=1; })
            {
                const div = input_t / rate;
                const measured:u128 = @intFromFloat(div);
                const fract = div - @trunc(div);
                
                if (fract > 0) {
                    std.debug.print(
                        " | {d} | {d}e{d} | Fract is not 0 | {d} | 0 | measured: {d} |\n",
                        .{ rate, mult, iters, input_t, fract }
                    );
                    break;
                }

                if ( expected_t != measured) 
                {
                    std.debug.print(
                        " | {d} | {d}e{d} | frame is wrong | {d} |  {d} | {d} |\n",
                        .{ rate, mult,iters, input_t, expected_t, measured }
                    );
                    break;
                    // break;
                }
            }
        }
    }

    std.debug.print("\n",.{});
}
