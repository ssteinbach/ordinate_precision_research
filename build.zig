const std = @import("std");

pub fn build(
    b: *std.Build,
) void 
{
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(
        .{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }
    );
    exe_mod.addIncludePath(b.path("src"));

    const exe = b.addExecutable(
        .{
            .name = "ordinate_precision_research",
            .root_module = exe_mod,
        }
    );

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) 
        |args| 
    {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(
        .{
            .root_module = exe_mod,
        }
    );
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const rational_mod = b.createModule(
        .{
            .root_source_file = b.path("src/rational_tests.zig"),
            .target = target,
            .optimize = optimize,
        },
    );
    rational_mod.addIncludePath(b.path("src"));
    const rational_tests = b.addTest(
        .{
            .root_module = rational_mod,
        }
    );
    const run_rational_unit_tests = b.addRunArtifact(rational_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_rational_unit_tests.step);
}
