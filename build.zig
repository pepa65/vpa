const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) !void {
    var target = b.standardTargetOptions(.{});

    const vpa = b.addExecutable("vpa", null);
    vpa.setTarget(target);
    vpa.setBuildMode(.ReleaseSmall);
    vpa.install();
    vpa.linkLibC();

    vpa.addIncludePath("include");
    vpa.defineCMacro("_GNU_SOURCE", "1");
    vpa.addCSourceFiles(&.{ "src/charm.c", "src/os.c", "src/vpn.c" }, &.{});
}
