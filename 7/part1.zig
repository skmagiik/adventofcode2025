const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try std.fs.cwd().openFile("input.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var lines = try std.ArrayList([]u8).initCapacity(alloc, 200);
    // Deallocated at end of function due to alloc.dupe for each line input

    while (true) {
        const line = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        lines.append(alloc, try alloc.dupe(u8, line)) catch |err| {
            std.debug.print("ERROR: {any}\n", .{err});
            return err;
        };
        //std.debug.print("{s}\n", .{line});
    }

    //const width: usize = lines.items[0].len;
    const height: usize = lines.items.len;
    //std.debug.print("Width: {d}\n", .{width});
    //std.debug.print("Height: {d}\n", .{height});

    const startingPos = std.mem.indexOf(u8, lines.items[0], "S").?;
    //std.debug.print("Staring Pos: {d}\n", .{startingPos});
    lines.items[1][startingPos] = '|';

    var min_x = startingPos;
    var max_x = startingPos;
    //std.debug.print("{s}\n", .{lines.items[0]});
    //std.debug.print("{s}\n", .{lines.items[1]});

    var num_splits: usize = 0;

    for (1..height - 1) |y| {
        for (min_x..max_x + 1) |x| {
            //std.debug.print("{d},{d} -> {c}\n", .{ x, y, lines.items[y][x] });
            if (lines.items[y][x] == '|') {
                if (lines.items[y + 1][x] == '^') {
                    // Split (assumption is we can never split at x == 0 || width-1 boundaries
                    num_splits += 1;
                    lines.items[y + 1][x - 1] = '|';
                    lines.items[y + 1][x + 1] = '|';
                    if (x == min_x) {
                        min_x -= 1;
                    }
                    if (x == max_x) {
                        max_x += 1;
                    }
                } else {
                    lines.items[y + 1][x] = '|';
                }
            }
        }
        //std.debug.print("{s}\n", .{lines.items[y + 1]});
    }

    std.debug.print("Result: {d}\n", .{num_splits});
    for (0..lines.items.len) |y| {
        alloc.free(lines.items[y]);
    }
    lines.deinit(alloc);
}

fn getSeekIdx(width: usize, x: usize, y: usize) usize {
    return ((width + 1) * y) + x;
}

test "demo.txt" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try std.fs.cwd().openFile("demo.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var lines = try std.ArrayList([]u8).initCapacity(alloc, 100);
    // Deallocated at end of function due to alloc.dupe for each line input

    while (true) {
        const line = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        try lines.append(alloc, try alloc.dupe(u8, line));
        //std.debug.print("{s}\n", .{line});
    }

    const width: usize = lines.items[0].len;
    const height: usize = lines.items.len;
    std.debug.print("Width: {d}\n", .{width});
    std.debug.print("Height: {d}\n", .{height});
    const startingPos = std.mem.indexOf(u8, lines.items[0], "S").?;
    std.debug.print("Staring Pos: {d}\n", .{startingPos});

    try std.testing.expectEqual(7, startingPos);

    lines.items[1][startingPos] = '|';

    var min_x = startingPos;
    var max_x = startingPos;
    std.debug.print("{s}\n", .{lines.items[0]});
    std.debug.print("{s}\n", .{lines.items[1]});

    var num_splits: usize = 0;

    for (1..height - 1) |y| {
        for (min_x..max_x + 1) |x| {
            //std.debug.print("{d},{d} -> {c}\n", .{ x, y, lines.items[y][x] });
            if (lines.items[y][x] == '|') {
                if (lines.items[y + 1][x] == '^') {
                    // Split (assumption is we can never split at x == 0 || width-1 boundaries
                    num_splits += 1;
                    lines.items[y + 1][x - 1] = '|';
                    lines.items[y + 1][x + 1] = '|';
                    if (x == min_x) {
                        min_x -= 1;
                    }
                    if (x == max_x) {
                        max_x += 1;
                    }
                } else {
                    lines.items[y + 1][x] = '|';
                }
            }
        }
        std.debug.print("{s}\n", .{lines.items[y + 1]});
    }

    for (0..lines.items.len) |y| {
        alloc.free(lines.items[y]);
    }
    lines.deinit(alloc);
    try std.testing.expectEqual(21, num_splits);
}
