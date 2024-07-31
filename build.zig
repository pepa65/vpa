// Req. 0.12 or later
const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });
	const vpa = b.addExecutable(.{
		.name = "vpa",
		.target = target,
		.optimize = optimize,
		.strip = true,
	});
	vpa.linkLibC();
	vpa.addIncludePath(b.path("include"));
	vpa.defineCMacro("_GNU_SOURCE", "1");
	const source_files = &.{ "src/charm.c", "src/os.c", "src/vpn.c" };
	vpa.addCSourceFiles(.{ .files = source_files });
	b.installArtifact(vpa);
	const run_cmd = b.addRunArtifact(vpa);
	run_cmd.step.dependOn(b.getInstallStep());
	if (b.args) |args| {
		run_cmd.addArgs(args);
	}
	const run_step = b.step("run", "Run the app");
	run_step.dependOn(&run_cmd.step);
}
