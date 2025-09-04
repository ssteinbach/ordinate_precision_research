//! A series of tests to explore floating point accuracy over large number
//! ranges
//!
//! See results.md for the results of these tests.
//! See README.md in this repository for a detailed description of methods and
//! analysis of results.

const std = @import("std");

const build_options = @import("build_options");

const rational_time = @cImport(
    {
        @cInclude("rational_time.c");
    }
);

/// Types to test.  f128 is inconsistently supported outside of zig.  Some
/// preliminary testing finds it to be ~100x slower than f64.
const TYPES = (
    if (build_options.ENABLED_F128)
        &.{ f32, f64, f128 }
    else 
        &.{ f32, f64, }
);

/// builds the standard rate array
fn rates_as(
    comptime T: type,
) [8]T
{
    return picture_rates_as(T) ++ audio_rates_as(T);
}

fn audio_rates_as(
    comptime T: type,
) [3]T
{
    return [_]T{
        44100.0,
        48000.0,
        192000.0,
    };
}

fn picture_rates_as(
    comptime T: type,
) [5]T
{
    return [_]T{
        24.0,
        24.0 * 1000.0 / 1001.0,
        25.0,
        30.0 * 1000.0 / 1001.0,
        120,
    };
}

/// Iteration limit (only hit when using f128)
const ITER_MAX = 10000000000;

const TABLE_HEADER_RAT_SUM_PROD = (
    \\ 
    \\ | Increment | Iterations | s | sum | product | iter/s |
    \\ |-----------|------------|---|-----|---------|--------|
);


pub fn rational_time_test_sum_product(
    writer: *std.io.Writer,
    parent_progress: std.Progress.Node,
) !void
{
    const progress = parent_progress.start(
        "Rational Time Sum/Product Test",
        2
    );
    defer progress.end();
    try writer.print(
        "\n\n## Integer Rational Sum/Product Test\n\nReports how many "
        ++ "iterations before the sum of rational integers is not equal to "
        ++ "the product for NTSC rates.\n{s}\n",
        .{TABLE_HEADER_RAT_SUM_PROD},
    );

    var buf: [1024]u8 = undefined;

    for (
        [_]rational_time.Rational32{
            rational_time.rational32_create(1001, 24 * 1000),
            rational_time.rational32_create(1001, 30 * 1000),
        }
    ) |time_increment| 
    {
        const buf_prog = try std.fmt.bufPrint(
            &buf, 
            "{d}/{d}",
            .{ time_increment.num, time_increment.den }
        );
        const loop_prog = progress.start(buf_prog, 1);
        defer loop_prog.end();

        // value to accumulate
        var current = rational_time.rational32_create(
            0,
            @intCast(time_increment.den),
        );

        // loop variables
        var mul = current;
        var is_equal = true;

        var i : usize = 0;

        var t_start = try std.time.Timer.start();
        while (
            is_equal
            and i < ITER_MAX
        ) 
        {
            current = rational_time.rational32_add(current, time_increment);

            i += 1;
            mul = rational_time.rational32_mul(
                time_increment,
                rational_time.rational32_create(@intCast(i), 1),
            );

            is_equal = rational_time.rational32_equal(current, mul);
        }

        const compute_time_s = (
            @as(f64, @floatFromInt(t_start.read())) / std.time.ns_per_s
        );
        const cycles_per_s = @as(f64, @floatFromInt(i)) / compute_time_s;

        const summed_time = (
            @as(f64, @floatFromInt(current.num)) 
            / @as(f64, @floatFromInt(current.den))
        );

        const time_str = try time_string(&buf, summed_time);

        try writer.print(
            " | {d}/{d} | {d} | {s} | {d}/{d} | {d}/{d} | {e:.2} |\n",
            .{
                time_increment.num, time_increment.den,
                i,
                time_str,
                current.num, current.den,
                mul.num, mul.den,
                cycles_per_s,
            },
        );
    }
}


pub fn rational_time_sum_product_scale(
    writer: *std.io.Writer,
    parent_progress: std.Progress.Node,
) !void
{
    const progress = parent_progress.start(
        "Rational Time sum/product w/ scale",
        2
    );
    defer progress.end();

    try writer.print(
        "\n\n## Integer Rational Sum/Product Test w/ 0.5 Scale\n\nReports"
        ++ " how many iterations before the sum of rational integers is not "
        ++ "equal to the product for NTSC rates.\n{s}\n",
        .{TABLE_HEADER_RAT_SUM_PROD},
    );

    var buf: [1024]u8 = undefined;

    for (
        [_]rational_time.Rational32{
            rational_time.rational32_create(1001, 24 * 1000),
            rational_time.rational32_create(1001, 30 * 1000),
        }
    ) |time_increment_in| 
    {
        const SCALE = rational_time.rational32_create(2.0, 1.0,);

        const time_increment = rational_time.rational32_div(
            time_increment_in,
            SCALE,
        );

        const buf_prog = try std.fmt.bufPrint(
            &buf, 
            "{d}/{d}",
            .{ time_increment.num, time_increment.den }
        );
        const loop_prog = progress.start(buf_prog, 1);
        defer loop_prog.end();

        // value to accumulate
        var current = rational_time.rational32_create(
            0,
            @intCast(time_increment.den),
        );

        // loop variables
        var mul = current;
        var is_equal = true;

        var i : usize = 0;

        var t_start = try std.time.Timer.start();
        while (is_equal and i < ITER_MAX) 
        {
            current = rational_time.rational32_add(current, time_increment);

            i += 1;
            mul = rational_time.rational32_mul(
                time_increment,
                rational_time.rational32_create(@intCast(i), 1),
            );

            is_equal = rational_time.rational32_equal(current, mul);
        }

        const compute_time_s = (
            @as(f64, @floatFromInt(t_start.read())) / std.time.ns_per_s
        );
        const cycles_per_s = @as(f64, @floatFromInt(i)) / compute_time_s;

        const summed_time = (
            @as(f64, @floatFromInt(current.num)) 
            / @as(f64, @floatFromInt(current.den))
        );

        const time_str = try time_string(&buf, summed_time);

        try writer.print(
            " | {d}/{d} | {d} | {s} | {d}/{d} | {d}/{d} | {e:.2} |\n",
            .{
                time_increment.num, time_increment.den,
                i,
                time_str,
                current.num, current.den,
                mul.num, mul.den,
                cycles_per_s,
            },
        );
    }
}

const TABLE_HEADER_RAT_LIMITS = (
    \\ 
    \\ | rate 1 | rate 2 | last index | wall clock time |
    \\ |--------|--------|------------|-----------------|
);

const TABLE_HEADER_RAT_TIME_LIMITS = (
    \\ 
    \\ | type | rate | last index | wall clock time |
    \\ |------|------|------------|-----------------|
);

pub fn number_type_limits(
    writer: *std.io.Writer,
) !void
{
    var buf : [1024]u8 = undefined;

    // integer limits
    inline for ([_]type{i32, i64, i128})
        |T|
    {
        const max_int = std.math.maxInt(T);
        const time_str = try time_string(
            &buf,
            @as(f64, @floatFromInt(max_int)) / 192000.0,
        );
        writer.print(
            " | {s} | {d} | {s} | \n",
            .{ 
                @typeName(T),
                max_int,
                time_str,
            }
        );
    }

    // float limits
    inline for ([_]type{ f32, f64, f128 })
        |T|
    {
        const float_max = std.math.floatMax(T);
        const time_str = try time_string(
            &buf,
            @as(f64, @floatCast(float_max)) / 24.0,
        );
        writer.print(
            " | {s} | {d} | {s} | \n",
            .{ 
                @typeName(T),
                float_max,
                time_str,
            }
        );
    }
}

pub fn integer_rational_limits(
    writer: *std.io.Writer,
) !void
{    
    writer.print(
        "\n\n## Integer Rational Limits\n\n"
        ++ "Derives the number of amount of time MAX_INT (for i32) represents "
        ++ "for an integer rational (i32/i32) at various media rates.  This "
        ++ "not take renormalization into consideration, which might occur "
        ++ "of accumulation or math.\n{s}\n"
        ,
        .{TABLE_HEADER_RAT_TIME_LIMITS},
    );

    var buf: [1024]u8 = undefined;

    const i_rates = [_]i32{ 24, 25, 30, 120, 44100, 48000, 192000 };
    var INCREMENTS : [i_rates.len + 2]rational_time.Rational32 = undefined;
    var RATE_STRINGS : [i_rates.len + 2][16]u8 = undefined;

    // integer rates
    for (i_rates, 0..)
        |rate, ind|
    {
        INCREMENTS[ind] = rational_time.rational32_create(1, rate);
        _ = try std.fmt.bufPrint(&RATE_STRINGS[ind], "{d}", .{ rate });
    }

    // fractional rates
    for ([_]i32{24, 30}, i_rates.len..i_rates.len + 2)
        |rate, ind|
    {
        INCREMENTS[ind] = rational_time.rational32_create(1001, rate * 1000);
        var f_val : f32 = @floatFromInt(rate);
        f_val *= (1000.0/1001.0);

        _ = try std.fmt.bufPrint(
            &RATE_STRINGS[ind],
            "{d}",
            .{ f_val }
        );
    }

    const max_index:f32 = @floatFromInt(std.math.maxInt(i32));

    for (INCREMENTS, 0..)
        |inc_a, ind|
    {
        const num: f32 = @floatFromInt(inc_a.num);
        const den: f32 = @floatFromInt(inc_a.den);

        const time_str = try time_string(
            &buf,
            (max_index*num)/den,
        );

        writer.print(
            " | {s} | {d} | {s} | \n",
            .{
                RATE_STRINGS[ind],
                max_index,
                time_str,
            },
        );
    }

    // set up next header
    writer.print( "\n{s}\n", .{ TABLE_HEADER_RAT_LIMITS, });


    for (INCREMENTS[0..INCREMENTS.len - 1], 0..)
        |inc_a, ind_a|
    {
        for (INCREMENTS[ind_a..], ind_a..)
            |inc_b, ind_b|
        {
            const inc_ab = rational_time.rational32_add(inc_a, inc_b);

            const den: f32 = @floatFromInt(inc_ab.den);

            const time_str = try time_string(
                &buf,
                (max_index)/den,
            );

            writer.print(
                " | {s} | {s} | {d}/{d} | {d} | {s} | \n",
                .{
                    RATE_STRINGS[ind_a],
                    RATE_STRINGS[ind_b],
                    inc_ab.num,
                    inc_ab.den,
                    max_index,
                    time_str,
                },
            );
        }
    }
}


const TABLE_HEADER_FP_SUM_PRODUCT = (
    \\ 
    \\ | rate | iterations | tolerance | wall clock time | iterations/s |
    \\ |------|------------|-----------|-----------------|--------------|
);

pub fn floating_point_product_vs_sum_test(
    writer: *std.io.Writer,
    parent_progress: std.Progress.Node,
) !void
{    
    const progress = parent_progress.start(
        "Sum/Product equality tests",
        TYPES.len,
    );
    defer progress.end();

    try writer.print(
        "\n\n## Sum/Product equality tests\nReports how many iterations "
        ++ "before the sum is not equal to the product by more than half a"
        ++ " frame\n",
        .{},
    );

    var buf: [1024]u8 = undefined;

    inline for (TYPES) 
        |T| 
    {
        const buf_prog = try std.fmt.bufPrint(
            &buf, 
            "{s}",
            .{@typeName(T)},
        );
        const loop_prog = progress.start(
            buf_prog,
            rates_as(T).len * 2,
        );
        defer loop_prog.end();

        try writer.print(
            "\n### Type: {s}\n{s}\n",
            .{ @typeName(T), TABLE_HEADER_FP_SUM_PRODUCT },
        );

        for (rates_as(T)) 
            |rate| 
        {
            const increment: T = @floatCast(1.0 / rate);

            for (
                &[_]T{
                    // half a frame
                    1.0 / (rate * 2),
                    // ms
                    5e-4,
                },
            ) |tolerance| 
            {
                const loop_prog_buf = try std.fmt.bufPrint(
                    &buf, 
                    "{s}: {d} hz [{d:.03}]",
                    .{@typeName(T), rate, tolerance},
                );
                loop_prog.setName(loop_prog_buf);
                defer loop_prog.completeOne();

                var t_start = try std.time.Timer.start();

                var current: T = 0;
                var iter: T = 0;

                while (
                    std.math.approxEqAbs(
                        T,
                        iter * increment,
                        current,
                        tolerance,
                    )
                    and iter < ITER_MAX
                ) 
                {
                    iter += 1;
                    current += increment;
                }

                const compute_time_s = (
                    @as(T, @floatFromInt(t_start.read())) / std.time.ns_per_s
                );
                const cycles_per_s = iter / compute_time_s;

                const time_str = try time_string(
                    &buf,
                    current,
                );

                try writer.print(
                    " | {d} | {d} | {d} | {s} | {e:0.2} |\n",
                    .{ rate, iter, tolerance, time_str, cycles_per_s },
                );
            }
        }
    }
}


pub fn floating_point_product_vs_sum_test_scale(
    writer: *std.io.Writer,
    parent_progress: std.Progress.Node,
) !void
{
    const progress = parent_progress.start(
        "Sum/Product equality tests (With a scale)",
        TYPES.len,
    );
    defer progress.end();

    try writer.print(
        "\n\n## Sum/Product equality tests\nReports how many iterations "
        ++ "before the sum is not equal to the product by more than half a"
        ++ " frame\n",
        .{},
    );

    var buf: [1024]u8 = undefined;

    inline for (TYPES) 
        |T| 
    {
        const buf_prog = try std.fmt.bufPrint(
            &buf, 
            "{s}",
            .{@typeName(T)},
        );
        const loop_prog = progress.start(
            buf_prog,
            rates_as(T).len
        );
        defer loop_prog.end();

        try writer.print(
            "\n### Type: {s}\n{s}\n",
            .{ @typeName(T), TABLE_HEADER_FP_SUM_PRODUCT },
        );

        for (rates_as(T)) 
            |rate| 
        {
            const loop_prog_buf = try std.fmt.bufPrint(
                &buf, 
                "{s}: {d} hz",
                .{@typeName(T), rate},
            );
            loop_prog.setName(loop_prog_buf);
            defer loop_prog.completeOne();
            const increment: T = @floatCast(0.5 * (1.0 / rate));

            for (
                &[_]T{
                    // half a frame
                    1.0 / (rate * 2),
                    // ms
                    // 5e-4,
                },
            ) |tolerance| 
            {
                var t_start = try std.time.Timer.start();

                var current: T = 0;
                var iter: T = 0;

                while (
                    std.math.approxEqAbs(
                        T,
                        iter * increment,
                        current,
                        tolerance,
                    )
                    and iter < ITER_MAX
                ) 
                {
                    iter += 1;
                    current += increment;
                }

                const compute_time_s = (
                    @as(T, @floatFromInt(t_start.read())) / std.time.ns_per_s
                );
                const cycles_per_s = iter / compute_time_s;

                const time_str = try time_string(
                    &buf,
                    current,
                );

                try writer.print(
                    " | {d} | {d} | {d} | {s} | {e:0.2} |\n",
                    .{ rate, iter, tolerance, time_str, cycles_per_s },
                );
            }
        }
    }
}


/// write a string with a suffix for the time scale (ie 10.1s) into buf
fn time_string(
    buf: []u8,
    val: anytype,
) ![]u8 
{
    return (
        // seconds
        if (val < 60)
            try std.fmt.bufPrint(buf, "{d:0.3}s", .{val})
        // minutes
        else if (val < 60 * 60)
            try std.fmt.bufPrint(buf, "{d:0.3}m", .{val / 60})
        // hours
        else if (val < 60 * 60 * 24)
            try std.fmt.bufPrint(
                buf,
                "{d:0.3}h",
                .{val / (60 * 60)}
            )
        // days
        else if (val < 60 * 60 * 24 * 365)
            try std.fmt.bufPrint(
                buf,
                "{d:0.3}d",
                .{val / (60 * 60 * 24)}
            )
        // years
        else
            try std.fmt.bufPrint(
                buf,
                "{d:0.3}y",
                .{val / (60 * 60 * 24 * 365)}
            )
    );
}


const TABLE_HEADER_TIME_TO_FRAME_N = (
    \\ 
    \\ | rate | iter | Failure | failure frame | expected | measured | iter/s |
    \\ |------|------|---------|---------------|----------|----------|--------|
);

pub fn floating_point_division_to_integer_test(
    writer: *std.io.Writer,
    parent_progress: std.Progress.Node,
) !void
{
    const progress = parent_progress.start(
        "Time to Frame Number Test",
        TYPES.len,
    );
    defer progress.end();

    try writer.print(
        "\n\n## Time to Frame Number Test\n" 
        ++ "Measures if the correct integer frame number and phase offset can" 
        ++ " be recovered from a large time value.\n",
        .{},
    );

    var buf:[1024]u8 = undefined;

    inline for (TYPES)
        |T| 
    {
        const buf_prog = try std.fmt.bufPrint(
            &buf, 
            "{s}",
            .{@typeName(T)},
        );
        const loop_prog = progress.start(
            buf_prog,
            rates_as(T).len
        );
        defer loop_prog.end();

        try writer.print(
            "\n### Type: {s}\n{s}\n",
            .{ @typeName(T), TABLE_HEADER_TIME_TO_FRAME_N },
        );

        if (T == f128) {
            // f128 causes an integer overflow
            continue;
        }

        for (rates_as(T))
            |rate| 
        {
            const loop_prog_buf = try std.fmt.bufPrint(
                &buf, 
                "{s}: {d} hz",
                .{@typeName(T), rate},
            );
            loop_prog.setName(loop_prog_buf);
            defer loop_prog.completeOne();

            var input_t: T = rate;
            var expected_t: u128 = 1.0;

            var iters: u128 = 0;
            const mult = 10;

            var t_start = try std.time.Timer.start();

            var measured: u128 = undefined;
            var msg: []const u8 = undefined;

            while (iters < ITER_MAX) 
            {
                const div : T = input_t / rate;
                const fract : T = div - @trunc(div);

                if (fract > 0) 
                {
                    msg = "Fract is not 0";
                    expected_t = 0;
                    break;
                }

                measured = @intFromFloat(div);

                if (expected_t != measured) 
                {
                    msg = "frame is wrong";
                    break;
                }

                input_t *= mult;
                expected_t *= mult;
                iters += 1; 
            }

            const compute_time_s = (
                @as(T, @floatFromInt(t_start.read())) 
                / std.time.ns_per_s
            );
            const cycles_per_s = (
                @as(T, @floatFromInt(iters)) 
                / compute_time_s
            );

            try writer.print(
                " | {d} | {d}e{d} | {s} | {d} | {s} | {d} | {d} | {e:0.2} | \n",
                .{
                    rate,
                    mult,
                    iters,
                    msg,
                    input_t,
                    try time_string(&buf, input_t),
                    expected_t,
                    measured,
                    cycles_per_s,
                },
            );
        }
    }
}


const TABLE_HEADER_SIN_DRIFT_TEST = (
    \\ 
    \\ | rate | target epsilon | iterations | s | iter/s |
    \\ |------|----------------|------------|---|--------|
);

pub fn sin_big_number_drift_test(
    writer: *std.io.Writer,
    parent_progress: std.Progress.Node,
) !void
{
    const progress = parent_progress.start(
        "sin big number drift test",
        TYPES.len,
    );
    defer progress.end();

    try writer.print(
        "\n\n## Sin Drift Test\n\n" 
        ++ "Measures the number of iterations of adding two pi to pi/4 before" 
        ++ " the sin value drifts more than half a frame from the value at"
        ++ " zero.\n",
        .{},
    );

    var buf: [1024]u8 = undefined;

    inline for (TYPES) 
        |T| 
    {
        const buf_prog = try std.fmt.bufPrint(
            &buf, 
            "{s}",
            .{@typeName(T)},
        );
        const loop_prog = progress.start(
            buf_prog,
            rates_as(T).len,
        );
        defer loop_prog.end();

        try writer.print(
            "\n### Type: {s}\n{s}\n",
            .{ @typeName(T), TABLE_HEADER_SIN_DRIFT_TEST },
        );

        for (rates_as(T))
            |rate| 
        {
            const loop_prog_buf = try std.fmt.bufPrint(
                &buf, 
                "{s}: {d} hz",
                .{@typeName(T), rate},
            );
            loop_prog.setName(loop_prog_buf);
            defer loop_prog.completeOne();

            //Initial value of pi/4
            var current_value: T = std.math.pi / 4.0;
            const initial_value = std.math.sin(current_value);
            var test_value = initial_value;
            var i: usize = 0;

            const TARGET_EPSILON: T = (1.0 / rate) / 2.0;

            var t_start = try std.time.Timer.start();

            while (
                @abs(test_value - initial_value) < TARGET_EPSILON
                and i < ITER_MAX
            ) 
                : (i += 1) 
            {
                test_value = std.math.sin(current_value);
                current_value = current_value + 2 * std.math.pi;
            }

            const compute_time_s = (
                @as(T, @floatFromInt(t_start.read())) 
                / std.time.ns_per_s
            );
            const cycles_per_s = @as(T, @floatFromInt(i)) / compute_time_s;
            const time_to_err_s = @as(T, @floatFromInt(i)) / rate;

            try writer.print(
                " | {d} | {d} | {d} | {s} | {e:0.2} | \n",
                .{
                    rate,
                    TARGET_EPSILON,
                    i,
                    try time_string(&buf, time_to_err_s),
                    cycles_per_s,
                },
            );
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

fn next_greater_multiple(
    writer: *std.io.Writer,
    comptime T: type,
    current: T,
    a: T,
    b: T
) !T
{
    const lcm = least_common_multiple(T, a, b);

    if (@mod(current, lcm) == 0) {
        return current + lcm;
    }
    try writer.print(
        "mod: {d} current: {d} lcm2: {d}\n",
        .{ @mod(current, lcm), current, lcm }
    );
    return (@ceil(current / lcm)) * lcm;
}


const TABLE_HEADER_PHASE_OFFSET = (
    \\ 
    \\ | rate_a | rate_b | iterations | next multiple | current_a | current_b | delta |
    \\ |--------|--------|------------|---------------|-----------|-----------|-------|
);

pub fn phase_offset_test(
    writer: *std.io.Writer,
    parent_progress: std.Progress.Node,
) !void
{
    const progress = parent_progress.start(
        "phase offset test",
        TYPES.len,
    );
    defer progress.end();

    try writer.print(
        "\n\n## Phase Offset Test\n\n" 
        ++ "Measures the number of iterations of finding the next common "
        ++ "multiple of two rates such that the sum of each of the "
        ++ "rates does not equal. Will terminate after 2 days of time.\n",
        .{},
    );

    var buf:[1024]u8 = undefined;

    inline for (TYPES) 
        |T| 
    {
        const buf_prog = try std.fmt.bufPrint(
            &buf, 
            "{s}",
            .{@typeName(T)},
        );
        const loop_prog = progress.start(
            buf_prog,
            picture_rates_as(T).len * picture_rates_as(T).len
        );
        defer loop_prog.end();

        try writer.print(
            "\n### Type: {s}\n{s}\n",
            .{ @typeName(T), TABLE_HEADER_PHASE_OFFSET },
        );

        for (picture_rates_as(T))
            |rate_a| 
        {
            for (picture_rates_as(T))
                |rate_b| 
            {
                const loop_prog_buf = try std.fmt.bufPrint(
                    &buf, 
                    "{s}: {d} hz x {d}",
                    .{@typeName(T), rate_a, rate_b},
                );
                loop_prog.setName(loop_prog_buf);
                defer loop_prog.completeOne();

                if (rate_a == rate_b) {
                    continue;
                }

                const inc_a_s : T = 1 / rate_a;
                const EPS_A = inc_a_s / 2;

                const inc_b_s : T = 1 / rate_b;
                const EPS_B = inc_b_s / 2;

                const TARGET_EPSILON = @max(EPS_A, EPS_B);

                if (inc_a_s == 0 or inc_b_s == 0) {
                    continue;
                }

                var current_a : T = 0;
                var current_b : T = 0;
                var next_multiple : T = 0;

                var i:usize = 0;

                // @TODO: find all points in which the phase lines up

                const lcm = least_common_multiple(T, rate_a, rate_b);

                while (
                    @abs(current_a - current_b) < TARGET_EPSILON 
                    and next_multiple < 60 * 60 * 24 * 2
                    and i < ITER_MAX
                ) 
                {
                    next_multiple = @as(T, @floatFromInt(i))*lcm;

                    while (@abs(next_multiple - current_a) > EPS_A) {
                        current_a += inc_a_s;
                    }

                    while (@abs(next_multiple - current_b) > EPS_B) {
                        current_b += inc_b_s;
                    }

                    i += 1;
                }

                try writer.print(
                    "| {d} | {d} | {d} | {d} | {s} | {d} | {d} | {d} |\n",
                    .{ 
                        rate_a, rate_b,
                        i, 
                        next_multiple,
                        try time_string(&buf, next_multiple),
                        current_a, current_b, current_a - current_b 
                    },
                );
            }
        }
    }
}

/// Run each test and report results
pub fn main(
) !u8
{
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = GPA.allocator();

    // fetch the path to write to from args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2)
    {
        std.log.err(
            "Usage: {s} path-to-output-report-file\n", 
            .{ args[0] },
        );
        return 1;
    }

    const fpath = std.os.argv[1];

    var buf:[1024]u8 = undefined;

    var outfile = try std.fs.cwd().createFileZ(
        fpath,
        .{},
    );

    var writer_parent = outfile.writer(&buf);
    const writer = &writer_parent.interface;

    defer outfile.close();

    const parent_progress = std.Progress.start(.{});
    defer parent_progress.end();

    const TESTS= &.{
        &rational_time_test_sum_product,
        &rational_time_sum_product_scale,
        &floating_point_product_vs_sum_test,
        &floating_point_product_vs_sum_test_scale,
        &floating_point_division_to_integer_test,
        &sin_big_number_drift_test,
        &phase_offset_test,
    };
    
    const progress = parent_progress.start(
        "Report Tests",
        TESTS.len,
    );
    defer progress.end();

    // per-thread data
    var threads: [TESTS.len]std.Thread = undefined;
    var inputs: [TESTS.len]std.io.Writer.Allocating = undefined;

    inline for (TESTS, 0..)
        |test_fn, i|
    {
        // configure the writer
        inputs[i] = std.io.Writer.Allocating.init(allocator);   
        const thread_writer = &inputs[i].writer;

        threads[i] = try std.Thread.spawn(
            .{},
            test_fn.*,
            .{ thread_writer, progress }
        );
    }

    // document header
    try writer.print(
        "# Ordinate Precision Exploration\n",
        .{},
    );

    for (threads, 0..)
        |thread, i|
    {
        thread.join();
        const txt = try inputs[i].toOwnedSlice();
        _ = try writer.write(txt);
        _ = try writer.write("\n");
        try writer.flush();

        allocator.free(txt);
        inputs[i].deinit();
    }

    try writer.print(
        "\n## Additional Notes\n\n* Tests have an iteartion limit of {d}.  "
        ++ "Tests that end at that being terminated and not running to "
        ++ "completion (in particular tests on f128).\n",
        .{ ITER_MAX },
    );

    try writer.flush();

    std.log.info("wrote report to: {s}\n", .{fpath});

    return 0;
}
