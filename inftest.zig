const std = @import("std");

// test "-0 + -1" 
// {
//     for (&[_]f32{ 0 })
//         |v|
//     {
//         inline for (&.{-1, 1}) 
//             |s|
//         {
//             const lhs = (s * v);
//             const rhs = -1;
//             const result = lhs + rhs;
//             std.debug.print("stuff: {d} + {d} = {d}\n", .{lhs, rhs, result});
//             std.debug.print("{d} < 0: {any}\n", .{lhs, lhs < 0 });
//         }
//     }
// }

const fakemath = struct {
    pub inline fn add(lhs: f32, rhs: f32) f32 { return lhs + rhs; }
    pub inline fn sub(lhs: f32, rhs: f32) f32 { return lhs - rhs; }
    pub inline fn mul(lhs: f32, rhs: f32) f32 { return lhs * rhs; }
    pub inline fn div(lhs: f32, rhs: f32) f32 { return lhs / rhs; }
    pub inline fn eql(lhs: f32, rhs: f32) bool { return lhs == rhs; }
    pub inline fn lt(lhs: f32, rhs: f32) bool { return lhs < rhs; }
    pub inline fn gt(lhs: f32, rhs: f32) bool { return lhs > rhs; }
    pub inline fn neg(v: f32) f32 { return 0 - v; }
    pub inline fn sqrt(v: f32) f32 { return std.math.sqrt(v); }
};

test "plot float behavior" 
{
    if (true)
    {
        return error.SkipZigTest;
    }

    const values = [_]f32 {
        0,
        -0.0,
        1,
        -1,
        std.math.inf(f32),
        -std.math.inf(f32),
        std.math.nan(f32),
    };

    std.debug.print("op test...\n\n", .{});

    const line_len = (&values).len;

    var line : [line_len+1]f32 = undefined;

    // binary operators
    inline for (&.{ "add", "sub", "mul", "div" })
        |op|
    {
        std.debug.print("\n\n{s}:\n    {any}\n----------------------------------------\n", .{op, values});
        for (values) 
            |lhs|
        {
            line[0] = lhs;
            for (values, 0..)
                |rhs, ind|
            {
                const result = @field(fakemath, op)(lhs, rhs);
                line[ind+1] = result;
                // std.debug.print(
                //     "{d} {s} {d} = {d}\n",
                //     .{
                //         lhs,
                //         op,
                //         rhs, 
                //         result
                //     },
                // );
            }

            std.debug.print("{d} | {any}\n", .{ line[0], line[1..] });
        }
    }

    // binary tests
    inline for (&.{"eql", "lt", "gt" })
        |op|
    {
        var l_b : [line_len + 1]bool = undefined;

        std.debug.print("\n\n{s}:\n    {any}\n----------------------------------------\n", .{op, values});
        for (values) 
            |lhs|
        {
            line[0] = lhs;
            for (values, 0..)
                |rhs, ind|
            {
                const result = @field(fakemath, op)(lhs, rhs);
                l_b[ind+1] = result;
                // std.debug.print(
                //     "{d} {s} {d} = {d}\n",
                //     .{
                //         lhs,
                //         op,
                //         rhs, 
                //         result
                //     },
                // );
            }

            std.debug.print("{d} | {any}\n", .{ line[0], l_b[1..] });
        }
    }

    // unary operators
    inline for (&.{"neg", "sqrt"})
        |op|
    {
        std.debug.print("\n\n{s}:\n----------------------------------------\n", .{op});
        for (values) 
            |lhs|
        {
            line[0] = lhs;
            const result = @field(fakemath, op)(lhs);
            line[1] = result;
            // std.debug.print(
            //     "{d} {s} {d} = {d}\n",
            //     .{
            //         lhs,
            //         op,
            //         rhs, 
            //         result
            //     },
            // );

            std.debug.print("{d} | {any}\n", .{ line[0], line[1] });
        }
    }
}

test "plot float accuracy"
{
    std.debug.print(
        "\n\nFloat Type Exploration\nReports how many iterations before "
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
            f64,
            // f128,
        }
    )
        |T|
    {
        std.debug.print(
            "\nType: {s}\n",
            .{
                @typeName(T),
            },
        );

        for (
            &[_]T{ 
                24.0,
                24.0 * 1000.0 / 1001.0,
                120,
                48000.0,
                192000.0,
            }
        )
            |rate|
        {
            std.debug.print(
                "  Rate: {d}\n",
                .{ rate }
            );

            for (
                &[_]T{
                    1.0 / (rate*2),
                    5e-4,
                }
            )
                |MIN_TOLERANCE|
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
                        const time_str = (
                            if (current < 60)
                                try std.fmt.bufPrint(&buf, "{d:0.3}s", .{ current })
                            else if (current < 60 * 60)
                                try std.fmt.bufPrint(&buf, "{d:0.3}m", .{ current / 60 })
                            else if (current < 60 * 60 * 24)
                                try std.fmt.bufPrint(&buf, "{d:0.3}h", .{ current / (60 * 60) })
                            else 
                                try std.fmt.bufPrint(&buf, "{d:0.3}d", .{ current / (60 * 60 * 24) })
                        );

                        std.debug.print(
                            "     {d} iterations to hit tolerance: {d} ({s} @ {d}fps)\n",
                            .{ iter, tolerance, time_str, rate }
                        );
                        tolerance *= 10;
                        break;
                    }

                   // if (current >= 60 * 60 * 24 * 4) {
                    //     std.debug.print("      ...more than 4 days of time.\n", .{});
                    //     break;
                    // }
                }
            }
        }
    }
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


test "time -> frame number test"
{
    std.debug.print(
        "\n\nTime to Frame Number Test\n"
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
        std.debug.print("\nType: {s}\n", .{ @typeName(T)});

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
                        "  Rate {d} [{d}e{d}] Fract is not 0 at: {d}, expected: 0 measured: {d}\n",
                        .{ rate, mult, iters, input_t, fract }
                    );
                    break;
                }

                if ( expected_t != measured) 
                {
                    std.debug.print(
                        "  Rate {d} [{d}e{d}] frame is wrong at: {d}, expected: {d} measured: {d}\n",
                        .{ rate, mult,iters, input_t, expected_t, measured }
                    );
                    break;
                    // break;
                }
            }
        }
    }
}

fn least_common_multiple(
    comptime T: type,
    a: T,
    b: T,
) T
{
    const a_i : u32 = @intFromFloat(a);
    const b_i : u32 = @intFromFloat(b);

    return (
        @abs(a * b) 
        / @as(T, @floatFromInt(std.math.gcd(a_i, b_i)))
    );
}

test "lcm"
{
    try std.testing.expectEqual(
        6,
        least_common_multiple(f32, 3, 2),
    );

    try std.testing.expectEqual(
        360,
        least_common_multiple(f32, 180, 24),
    );
}



fn next_greater_multiple(
    comptime T: type,
    current: T,
    a: T,
    b: T
) T
{
    const lcm = least_common_multiple(T, a, b);

    if (@mod(current, lcm) == 0) {
        return current + lcm;
    }
    return (@ceil(current / lcm)) * lcm;
}

test "ngm"
{
    try std.testing.expectEqual(
        12,
        next_greater_multiple(f32, 6, 2, 3),
    );
    try std.testing.expectEqual(
        12,
        next_greater_multiple(f32, 7, 2, 3),
    );
    try std.testing.expectEqual(
        72,
        next_greater_multiple(f32, 49, 6, 8),
    );
    try std.testing.expectEqual(
        72,
        next_greater_multiple(f32, 48, 6, 8),
    );
    try std.testing.expectEqual(
        48,
        next_greater_multiple(f32, 45, 6, 8),
    );
}


 // test "3:2 pulldown demo test"
 // {
 //     //
 //     // goal is to demonstrate where different floats aren't accurate enough
 //     // to resolve the correct frame number
 //     //
 //     // show how something like the phase ordinate can hold accuracy over
 //     // longer runs
 //     //
 //
 //     inline for (
 //         &.{
 //             // error for floating numbers gets worse as the number gets bigger
 //             f32,
 //             f64,
 //             f128, 
 //         }
 //     )
 //        |T|
 //    {
 //        std.debug.print(
 //            "Type: {s}\n",
 //            .{ @typeName(T) },
 //        );
 //
 //
 //        // 4 * 24 = 96
 //        //    every four frames: 1 more frame
 //        // 4 * 30 = 120
 //        //
 //        // gcd(24, 30) = 6, 24/6 = 4 => every four frames double the frame
 //        // ...
 //        // the start of the 120th frame should be the same time for each cycle
 //        //
 //        // test 1 : sum test, add 1/24 1/96khz etc and show that round numbers
 //        //          are no longer where they are supposed to be
 //        // test 2 : product test, add 1/24 1/96khz etc and show that round
 //        //          numbers are no longer where they are supposed to be
 //
 //        const inc_a : T = 1.0/24.0;
 //        // const inc_b : T = 24.0 * 1001.0/1000.0;
 //        const inc_b : T = 1.0/30.0;
 //
 //        std.debug.print(
 //            "Type: {s} inc_a: {d:0.6} inc_b: {d:0.6} \n",
 //            .{ @typeName(T), inc_a, inc_b },
 //        );
 //
 //        // var next : T = next_greater_multiple(T, 0, inc_a, inc_b);
 //
 //        const tolerance : T = 0.01;
 //
 //        var i:T = 1;
 //        while (i < 5000000)
 //            : (i += 1)
 //        {
 //            const m_a = @mod(i, inc_a);
 //            const m_b = @mod(i, inc_b);
 //            if (
 //                std.math.approxEqAbs(T, m_a, 0, tolerance)
 //                and std.math.approxEqAbs(T, m_b, 0, tolerance)
 //            )
 //            {
 //                std.debug.print(
 //                    "i: {d} next: {d} mod(0, inc_a): {d:0.5} mod(0, inc_b): {d:0.5}\n",
 //                    // .{ i, next, m_a, m_b  }
 //                    .{ i,0, m_a, m_b  }
 //                );
 //                // next = next_greater_multiple(T, next, inc_a, inc_b);
 //                break;
 //            }
 //        }
 //    }
 // }
