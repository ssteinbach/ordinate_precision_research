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

const rational_time = @cImport(
    {
        @cInclude("rational_time.c");
    }
);

const TABLE_HEADER_FP_SUM_PRODUCT = (
\\ 
\\ | rate | iterations | tolerance | wall clock time | iterations/s |
\\ |------|------------|-----------|-----------------|--------------|
);

const TYPES = &.{
    f32,
    f64,
    // f128,
};

const RATES = [_]comptime_float{
    24.0,
    24.0 * 1000.0 / 1001.0,
    30.0 * 1000.0 / 1001.0,
    120,
    44100.0,
    48000.0,
    192000.0,
};

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

    var buf : [1024]u8 = undefined;

    inline for (TYPES) 
        |T|
    {
        std.debug.print(
            "\n### Type: {s}\n{s}\n",
            .{ @typeName(T), TABLE_HEADER_FP_SUM_PRODUCT},
        );

        for (
            [_]T{
                24.0,
                24.0 * 1000.0 / 1001.0,
                30.0 * 1000.0 / 1001.0,
                120,
                44100.0,
                48000.0,
                192000.0,
            }
        ) |rate|
        {
            const increment : T = @floatCast(1.0 / rate);

            for (
                &[_]T{
                    // half a frame
                    1.0 / (rate*2),
                    // ms
                    5e-4,
                }
            ) |tolerance|
            {
                var t_start = try std.time.Timer.start();

                var current : T = 0;
                var iter : T = 0;

                while (
                    std.math.approxEqAbs(
                        T,
                        iter * increment,
                        current,
                        tolerance,
                    )
                )
                {
                    iter += 1;
                    current += increment;
                }

                const compute_time_s = @as(T, @floatFromInt(t_start.read())) / std.time.ns_per_s;
                const cycles_per_s = iter / compute_time_s;

                const time_str = try time_string(
                    &buf,
                    current,
                );

                std.debug.print(
                    " | {d} | {d} | {d} | {s} | {e:0.2} |\n",
                    .{ rate, iter, tolerance, time_str, cycles_per_s }
                );
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
            try std.fmt.bufPrint(
                buf,
                "{d:0.3}s",
                .{ val }
            )
        else if (val < 60 * 60)
            try std.fmt.bufPrint(
                buf,
                "{d:0.3}m",
                .{ val / 60 }
            )
        else if (val < 60 * 60 * 24)
            try std.fmt.bufPrint(
                buf,
                "{d:0.3}h",
                .{ val / (60 * 60) }
            )
        else 
            try std.fmt.bufPrint(
                buf,
                "{d:0.3}d",
                .{ val / (60 * 60 * 24) }
            )
    );
}


 const TABLE_HEADER_TIME_TO_FRAME_N = (
 \\ 
 \\ | rate | iter | Failure | failure frame | expected | measured | iter/s |
 \\ |------|------|---------|---------------|----------|----------|--------|
 );


 test "Floating point division to integer test"
 {
     std.debug.print(
         "\n\n## Time to Frame Number Test\n"
         ++ "Measures if the correct integer frame number and phase offset can"
         ++ " be recovered from a large time value.\n"
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
                 44100,
                 48000,
                 192000,
             }
         ) |rate|
         {
             var input_t:T = rate;
             var expected_t:u128 = 1.0;

             var iters:usize = 0;
             const mult = 10; 

             var t_start = try std.time.Timer.start();

             var measured : u128 = undefined;
             var msg : []const u8 = undefined;

             while (true)
                 : ({ input_t *= mult; expected_t *= mult; iters+=1; })
             {
                 const div = input_t / rate;
                 measured = @intFromFloat(div);
                 const fract = div - @trunc(div);

                 if (fract > 0) 
                 {
                     msg = "Fract is not 0";
                     expected_t = 0;
                     break;
                 }

                 if (expected_t != measured) 
                 {
                     msg = "frame is wrong";
                     break;
                 }
             }

             const compute_time_s = @as(T, @floatFromInt(t_start.read())) / std.time.ns_per_s;
             const cycles_per_s = @as(T, @floatFromInt(iters)) / compute_time_s;

             std.debug.print(
                 " | {d} | {d}e{d} | {s} | {d} |  {d} | {d} | {e:0.2} | \n",
                 .{ rate, mult, iters, msg, input_t, expected_t, measured, cycles_per_s }
             );
         }
     }

     std.debug.print("\n",.{});
 }

 const TABLE_HEADER_SIN_DRIFT_TEST = (
 \\ 
 \\ | type | target epsilon | iterations | s | iter/s |
 \\ |------|----------------|------------|---|--------|
 );

 test "sin big number drift test" 
 {
     std.debug.print(
         "\n\n## Sin Drift Test\n\n"
         ++ "Measures the number of iterations of adding two pi to pi/4 before"
         ++ " the sin value drifts more than half a 192khz frame from the value"
         ++ "at zero.\n{s}\n"
         ,
         .{TABLE_HEADER_SIN_DRIFT_TEST}
     );

     var buf : [1024]u8 = undefined;

     // @TODO: structure like other tests, split by type and add more rates

     inline for ( 
         &.{
             // f16,
             f32, 
             f64,
         }
     ) |T|
     {

         const rate : T = 192000;

         //Initial value of pi/4
         var current_value : T = std.math.pi / 4.0;
         const initial_value = std.math.sin(current_value);
         var test_value = initial_value;
         var i : usize = 0;

         // half a frame at 192khz
         const TARGET_EPSILON : T = (1.0 / rate) / 2.0;

         var t_start = try std.time.Timer.start();

         // # Run the iterations
         while (@abs(test_value - initial_value) < TARGET_EPSILON)
             : (i += 1)
         {
             test_value = std.math.sin(current_value);
             current_value = current_value + 2 * std.math.pi;
         }

         const compute_time_s = @as(T, @floatFromInt(t_start.read())) / std.time.ns_per_s;
         const cycles_per_s = @as(T, @floatFromInt(i)) / compute_time_s;
         const time_to_err_s = @as(T, @floatFromInt(i)) / rate;

         std.debug.print(
             " | {s} | {d} | {d} | {s} | {e:0.2} | \n",
             .{ @typeName(T), TARGET_EPSILON, i, try time_string(&buf, time_to_err_s), cycles_per_s }
         );
     }
 }

 const TABLE_HEADER_RAT_SUM_PROD = (
 \\ 
 \\ | Increment | Iterations | s | iter/s |
 \\ |-----------|------------|---|--------|
 );

test "rational time test"
{
    std.debug.print(
        "\n\n## Integer Rational Test\n\nReports how many iterations before "
        ++ "the sum of rational integers of vary rates is not equal to the "
        ++ "product for NTSC rates.\n{s}\n",
        .{ TABLE_HEADER_RAT_SUM_PROD }
    );

    var buf : [1024]u8 = undefined;
    
    for (
        [_]rational_time.Rational32{
            // rational_time.rational32_create(1, 24),
            // rational_time.rational32_create(24*1000, 1001),
            // rational_time.rational32_create(30*1000, 1001),
            rational_time.rational32_create(1001, 24*1000),
            rational_time.rational32_create(1001, 30*1000),
            // rational_time.rational32_create(1, 120),
            // rational_time.rational32_create(1, 44100),
            // rational_time.rational32_create(1, 48000),
            // rational_time.rational32_create(1, 192000),
        }
    ) |time_increment|
    {
        // value to accumulate
        var current = rational_time.rational32_create(0, @intCast(time_increment.den));

        // iteration count
        var i = rational_time.rational32_create(0, 1);

        var is_equal = true;

        var mul = current;

        var t_start = try std.time.Timer.start();

        while (is_equal)
        {
            current = rational_time.rational32_add(
                current,
                time_increment
            );
            i.num += 1;

            mul = rational_time.rational32_mul(time_increment, i);

            is_equal = rational_time.rational32_equal(current,mul);

        }

        const compute_time_s = @as(f64, @floatFromInt(t_start.read())) / std.time.ns_per_s;
        const cycles_per_s = @as(f64, @floatFromInt(i.num)) / compute_time_s;

        // std.debug.print("current: {d}/{d} \n", .{ current.num, current.den });
        // std.debug.print("mul: {d}/{d} \n", .{ mul.num, mul.den });
        // std.debug.print(
        //     "current == mul, {any}\n",
        //     .{ is_equal }
        // );

        // @TODO add the time to fail + cycles_per_s

        const summed_time = (
            @as(f64, @floatFromInt(current.num)) 
            / @as(f64, @floatFromInt(current.den))
        ) ;
        const time_str = try time_string(&buf, summed_time);

        std.debug.print(
            " | {d}/{d} | {d} | {s} | {e:.2} |\n",
            .{ time_increment.num, time_increment.den, i.num, time_str, cycles_per_s }
        );
    }
    std.debug.print( "\n", .{},);
}

