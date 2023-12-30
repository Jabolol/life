const std = @import("std");
const Builder = std.build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const output_dir: []const u8 = "../www/static";
    const lib = b.addSharedLibrary(.{
        .name = "life",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = .{ .cpu_arch = .wasm32, .os_tag = .freestanding },
        .optimize = .ReleaseSafe,
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
    });
    lib.rdynamic = true;

    const install = b.addInstallFileWithDir(
        lib.getEmittedBin(),
        .{ .custom = output_dir },
        b.fmt("{s}.wasm", .{lib.name}),
    );

    install.step.dependOn(&lib.step);
    b.default_step.dependOn(&install.step);

    const exe = b.addExecutable(.{
        .name = "life",
        .root_source_file = .{ .path = "src/parser.zig" },
        .target = b.standardTargetOptions(.{}),
        .optimize = .ReleaseSafe,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("parse", "Parse all the pattern files under `./assets/` to `./www/static/patterns.json`");
    run_step.dependOn(&run_cmd.step);
}
