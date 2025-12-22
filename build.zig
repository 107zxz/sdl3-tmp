const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "template",
        .root_module = exe_mod,
    });

    const sdl3 = b.dependency("sdl3", .{
        .target = target,
        .optimize = std.builtin.OptimizeMode.ReleaseFast,
        .ext_image = true,
        .ext_ttf = true,
        .image_enable_png = true,
    });
    exe.root_module.addImport("sdl3", sdl3.module("sdl3"));
    b.installArtifact(exe);

    // Check step
    const exe_check = b.addExecutable(.{
        .name = "template",
        .root_module = exe_mod,
    });

    const check = b.step("check", "Check if game compiles");
    check.dependOn(&exe_check.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

