const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const Language = enum { russian, esperanto };

    var lang = b.option(Language, "language", "The language to use") orelse @panic("language option must be set");
    var word_count = b.option(usize, "word_count", "The amount of words to check for") orelse @panic("The word_count must be set");
    var word_length = b.option(usize, "word_length", "The length of the words we are checking for") orelse @panic("The word_length must be set");

    var options = b.addOptions();
    options.addOption(Language, "language", lang);
    options.addOption(usize, "word_count", word_count);
    options.addOption(usize, "word_length", word_length);

    const exe = b.addExecutable(.{
        .name = "LetterUniqueSolve",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addOptions("options", options);
    exe.linkLibC();
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
