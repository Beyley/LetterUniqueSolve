const std = @import("std");
const options = @import("options");

pub fn binomial(n: usize, k: usize) usize {
    var result: usize = n;
    for (2..(k + 1)) |i| {
        result *= (n - i + 1);
        result /= i;
    }
    return result;
}

pub const letters = switch (options.language) {
    .esperanto => &.{
        'a',
        'b',
        'c',
        'ĉ',
        'd',
        'e',
        'f',
        'g',
        'ĝ',
        'h',
        'ĥ',
        'i',
        'j',
        'ĵ',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        'ŝ',
        't',
        'u',
        'ŭ',
        'v',
        'z',
    },
    .russian => &.{
        'а',
        'б',
        'в',
        'г',
        'д',
        'е',
        'ё',
        'ж',
        'з',
        'и',
        'й',
        'к',
        'л',
        'м',
        'н',
        'о',
        'п',
        'р',
        'с',
        'т',
        'у',
        'ф',
        'х',
        'ц',
        'ч',
        'ш',
        'щ',
        'ъ',
        'ы',
        'ь',
        'э',
        'ю',
        'я',
        '\'',
        '-',
    },
};

const IntType = std.meta.Int(.unsigned, letters.len);

const used_words = options.word_count;
const word_length = options.word_length;

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    std.debug.print("settings: {d} words, {d} characters long\n", .{ used_words, word_length });

    const words_orig = switch (options.language) {
        .esperanto => try @import("load.zig").loadWordsEo(allocator, "words.csv", word_length),
        .russian => try @import("load.zig").loadWordsRu(allocator, "russian.csv", word_length),
    };

    std.debug.print("loaded {d} words\n", .{words_orig.len});

    var words = std.ArrayList([]const u8).init(allocator);
    defer words.deinit();
    //only do one allocation
    try words.ensureTotalCapacity(words_orig.len);

    blk: for (words_orig, 0..) |word, i| {
        _ = i;
        var num: IntType = 0;
        var iter = std.unicode.Utf8Iterator{ .bytes = word, .i = 0 };
        var j: usize = 0;
        while (iter.nextCodepoint()) |codepoint| {
            if (std.mem.indexOf(u21, letters, &.{codepoint})) |letter_index| {
                const bit = @shlExact(@as(IntType, 1), @intCast(letter_index));
                //If the bit is already set, skip this word (eg. if the word has duped letters)
                if (num & bit != 0) continue :blk;
                //Set the bit
                num |= bit;
            } else {
                std.debug.print("{u}\n", .{codepoint});
                @panic("unknown letter?");
            }

            j += 1;
        }
        try words.append(word);
        // continue :blk;
    }

    std.debug.print("pruned down to {d} words\n", .{words.items.len});

    var words_small: []IntType = try allocator.alloc(IntType, words.items.len);
    defer allocator.free(words_small);
    @memset(words_small, 0);

    for (words.items, 0..) |word, i| {
        var iter = std.unicode.Utf8Iterator{ .bytes = word, .i = 0 };
        var j: usize = 0;
        while (iter.nextCodepoint()) |codepoint| {
            if (std.mem.indexOf(u21, letters, &.{codepoint})) |letter_index| {
                words_small[i] |= @shlExact(@as(IntType, 1), @intCast(letter_index));
            } else {
                std.debug.print("{u}\n", .{codepoint});
                @panic("unknown letter?");
            }

            j += 1;
        }
        // std.debug.print("a {s}\n", .{words.items[i]});
    }

    //Get the amount of combinations required
    const combination_count = binomial(words.items.len, used_words);

    std.debug.print("iterating through {d} combinations\n", .{combination_count});

    //A list of all the found combinations
    var found = std.ArrayList([used_words]usize).init(allocator);
    defer found.deinit();

    var combination: [used_words]usize = undefined;
    //Get the first lexographic set
    for (&combination, 0..) |*item, i| {
        item.* = i;
    }

    const mult_table = comptime blk: {
        var table: [used_words]usize = undefined;

        for (&table, 0..) |*element, i| {
            element.* = (i + 1) * word_length;
        }

        break :blk table;
    };

    loop: while (true) {
        // std.debug.print("{d}\n", .{combination});
        var total: IntType = 0;

        for (&combination, 0..) |item, i| {
            total |= words_small[item];

            //If we have found duplicate bits, skip to the next branch of combinations
            if (@popCount(total) != mult_table[i]) {
                if (combination[i] == words_small.len - 1) {
                    //If we have reached the end of the combinations, break
                    if (!next_combination(used_words, &combination, words_small.len)) {
                        std.debug.print("breaking...\n", .{});
                        break :loop;
                    }

                    continue :loop;
                }

                var new_combination = combination;

                //Increment the count of the current
                new_combination[i] += 1;
                //Iterate from the next item to the last item
                for ((i + 1)..new_combination.len) |j| {
                    //Set the item to the last item + 1
                    new_combination[j] = new_combination[j - 1] + 1;

                    if (new_combination[j] >= words_small.len) {
                        // std.debug.print("huh...\n", .{});

                        //If we have reached the end of the combinations, break
                        if (!next_combination(used_words, &combination, words_small.len)) {
                            std.debug.print("breaking 2...\n", .{});
                            break :loop;
                        }
                        // std.debug.print("done..? {d}\n", .{combination});

                        continue :loop;
                    }
                }

                combination = new_combination;

                continue :loop;
            }
        }

        std.debug.print("found set /", .{});
        for (&combination) |found_idx| {
            std.debug.print("{s}/", .{words.items[found_idx]});
        }
        std.debug.print("\n", .{});
        try found.append(combination);

        //If we have reached the end of the combinations, break
        if (!next_combination(used_words, &combination, words_small.len)) {
            std.debug.print("breaking 2...\n", .{});
            break;
        }
    }
}

fn next_combination(comptime used_items: comptime_int, combination: *[used_items]usize, items_count: usize) bool {
    var i: usize = 1;
    while (i <= used_items) : (i += 1) {
        if (combination[used_items - i] < items_count - i) {
            combination[used_items - i] += 1;
            var j: usize = used_items - i + 1;
            while (j < used_items) : (j += 1) {
                combination[j] = combination[j - 1] + 1;
            }

            return true;
        }
    }
    return false;
}
