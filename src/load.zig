const std = @import("std");

const letters = @import("main.zig").letters;

pub fn loadWords(allocator: std.mem.Allocator, path: []const u8, word_length: usize) ![]const []const u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var data = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(data);

    var list = std.ArrayList([]const u8).init(allocator);
    errdefer list.deinit();

    var lines_iter = std.mem.split(u8, data, "\n");
    //Ignore the first line
    _ = lines_iter.next();
    while (lines_iter.next()) |line| {
        //Skip any lines with more than 3 ,
        if (std.mem.count(u8, line, ",") != 3) continue;

        var comma_iter = std.mem.split(u8, line, ",");
        _ = comma_iter.next(); //ignore raw esperanto
        _ = comma_iter.next(); //ignore raw lower esperanto
        var esperanto = comma_iter.next() orelse unreachable;
        {
            var codepoint_iter = std.unicode.Utf8Iterator{ .bytes = esperanto, .i = 0 };
            var skip = false;
            while (codepoint_iter.nextCodepoint()) |codepoint| {
                if (std.mem.indexOf(u21, letters, &.{codepoint}) == null) {
                    skip = true;
                    break;
                }
            }
            if (skip) continue;
        }
        var num_str = comma_iter.next() orelse unreachable;
        // std.debug.print("num str {s} esperanto {s}\n", .{ num_str, esperanto });
        var num = try std.fmt.parseInt(usize, num_str, 10);

        //If the word is not the length we are looking for, ignore it
        if (num != word_length) continue;

        try list.append(try allocator.dupe(u8, esperanto));
    }

    return list.toOwnedSlice();
}
