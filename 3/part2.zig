const std = @import("std");

fn getJoltage(input: []const u8, output_len: usize) !usize {
    //std.debug.print("getJoltage: {s}\n", .{input});
    const input_len = input.len;

    var output: usize = 0;
    var last_used_index: usize = 0;

    // 0123456789ABCDEF xxxxxxxxxxxYYYYY ZYYYYYxxxxxxxxxx
    // ZYYYYYxxxxxxxxxx
    // 8111111111111119
    // YYYYxxxxxxxxxxxx
    // 81111111111xxxx9
    // 811111111111119
    // 234234234234278
    // --ZYYxxxxxxxxxx
    // output_index = 1
    // remaining chars = 12-output_index (11)
    //

    for (0..output_len) |output_index| {
        var leading_value: usize = 0;
        const starting_index: usize = last_used_index;
        //std.debug.print("Checking idx range: {d} - {d}\n", .{ starting_index, (input_len - (12 - output_index)) });
        for (starting_index..(input_len - ((output_len - 1) - output_index))) |i| {
            //std.debug.print("\tChecking idx:{d}, last_used_idx {d}\n", .{ i, last_used_index });
            const char_val = try std.fmt.parseInt(usize, input[i .. i + 1], 10);
            //std.debug.print("\t\tinput[{d}..{d}] = char_val: {d}\n", .{ i, i + 1, char_val });
            if (char_val == 9) {
                last_used_index = i + 1;
                leading_value = char_val;
                break;
            }

            if (char_val > leading_value) {
                last_used_index = i + 1;
                leading_value = char_val;
            }
        }
        output += try std.math.powi(usize, 10, (output_len - 1) - output_index) * leading_value;
        //std.debug.print("Output {d} from idx {d}\n", .{ output, last_used_index - 1 });
    }
    return output;
}

test "getJoltage" {
    try std.testing.expectEqual(987654321111, getJoltage("987654321111111", 12));
    try std.testing.expectEqual(811111111119, getJoltage("811111111111119", 12));
    try std.testing.expectEqual(434234234278, getJoltage("234234234234278", 12));
    try std.testing.expectEqual(888911112111, getJoltage("818181911112111", 12));
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
        const joltage = try getJoltage(battery, 12);
        //std.debug.print("Joltage: {d}\n", .{joltage});
        sum += joltage;
    }

    std.debug.print("Result: {d}\n", .{sum});
}
