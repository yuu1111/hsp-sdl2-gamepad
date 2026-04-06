const std = @import("std");

pub fn build(b: *std.Build) void {
    // HSP 3.5 is 32-bit, so we target x86 Windows
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86,
            .os_tag = .windows,
            .abi = .msvc,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "gamepad",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gamepad.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = false,
        }),
        .linkage = .dynamic,
    });

    // Link kernel32 for LoadLibrary/GetProcAddress/FreeLibrary
    lib.root_module.linkSystemLibrary("kernel32", .{});

    b.installArtifact(lib);
}
