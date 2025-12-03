const std = @import("std");

fn getJoltage(input: []const u8) !usize {
    //std.debug.print("getJoltage: {s}\n", .{input});
    const input_len = input.len;

    var leading_index: usize = 0;
    var leading_value: usize = 0;
    for (0..input_len - 1) |i| {
        const char_val = try std.fmt.parseInt(usize, input[i .. i + 1], 10);
        //std.debug.print("Checking {d}: {d}\n", .{ i, char_val });
        if (char_val == 9) {
            leading_index = i;
            leading_value = char_val;
            break;
        }

        if (char_val > leading_value) {
            leading_index = i;
            leading_value = char_val;
        }
    }
    var trailing_index: usize = 1;
    var trailing_value: usize = 0;
    for (leading_index + 1..input_len) |i| {
        const char_val = try std.fmt.parseInt(usize, input[i .. i + 1], 10);
        //std.debug.print("Checking {d}: {d}\n", .{ i, char_val });
        if (char_val == 9) {
            trailing_index = i;
            trailing_value = char_val;
            break;
        }

        if (char_val > trailing_value) {
            trailing_index = i;
            trailing_value = char_val;
        }
    }
    return leading_value * 10 + trailing_value;
}

test "getJoltage" {
    try std.testing.expectEqual(98, getJoltage("987654321111111"));
    try std.testing.expectEqual(89, getJoltage("811111111111119"));
    try std.testing.expectEqual(78, getJoltage("234234234234278"));
    try std.testing.expectEqual(92, getJoltage("818181911112111"));
}

pub fn main() !void {
    const f = try std.fs.cwd().openFile("input.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);
    var sum: usize = 0;

    while (true) {
        const battery = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        //std.debug.print("Battery: {s}\n", .{battery});
        const joltage = try getJoltage(battery);
        //std.debug.print("Joltage: {d}\n", .{joltage});
        sum += joltage;
    }

    std.debug.print("Result: {d}\n", .{sum});
}
