const std = @import("std");

const Position = struct {
    x: usize,
    y: usize,
};

const Grid = struct {
    data: std.ArrayList(std.ArrayList(u8)),
    width: usize,
    height: usize,
    alloc: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Grid {
        if (height == 0) {
            return error.HeightIsZero;
        }
        return .{
            .alloc = allocator,
            .width = width,
            .height = height,
            .data = try std.ArrayList(std.ArrayList(u8)).initCapacity(allocator, height),
        };
    }

    fn initFromReader(allocator: std.mem.Allocator, reader: *std.fs.File.Reader) !Grid {
        var width: usize = 0;
        var height: usize = 0;
        while (true) {
            const line = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
                error.EndOfStream => {
                    break;
                },
                else => |e| {
                    return e;
                },
            };
            if (width == 0) {
                width = line.len;
            }
            height += 1;
        }
        //std.debug.print("Size: {d} x {d}\n", .{ width, height });

        try reader.seekTo(0);
        var grid = try Grid.init(allocator, width, height); //{ .width = width, .height = height, .alloc = allocator };

        for (0..height) |_| {
            const line = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
                else => |e| {
                    return e;
                },
            };
            //std.debug.print("{d}: {s}\n", .{ y, line });
            var row = try std.ArrayList(u8).initCapacity(allocator, width);
            for (0..width) |x| {
                try row.append(allocator, line[x]);
            }
            try grid.data.append(allocator, row);
        }
        return grid;
    }

    fn deinit(self: *Grid) void {
        for (self.data.items) |*row| {
            row.deinit(self.alloc);
        }
        self.data.deinit(self.alloc);
    }

    fn getChar(self: *Grid, x: usize, y: usize) u8 {
        return self.data.items[y].items[x];
    }

    fn removeRoll(self: *Grid, x: usize, y: usize) void {
        self.data.items[y].items[x] = 'x';
    }

    fn checkLocation(self: *Grid, x: usize, y: usize) bool {
        const posc = self.getChar(x, y);
        //std.debug.print("Checking {d}, {d} => {c}\n", .{ x, y, posc });
        if (posc != '@') {
            return false;
        }
        var rolls: usize = 0;
        var w_min: usize = 0;
        var w_max: usize = 3;
        var h_min: usize = 0;
        var h_max: usize = 3;
        if (x == 0) {
            w_min = 1;
        } else if (x == self.width - 1) {
            w_max = 2;
        }
        if (y == 0) {
            h_min = 1;
        } else if (y == self.height - 1) {
            h_max = 2;
        }
        yloop: for (h_min..h_max) |yi| {
            for (w_min..w_max) |xi| {
                if (xi == 1 and yi == 1) {
                    continue;
                }
                const c = self.getChar(x + xi - 1, y + yi - 1);
                if (c == '@') {
                    rolls += 1;
                }
                //std.debug.print("{c}", .{c});
                if (rolls == 4) {
                    break :yloop;
                }
            }
            //std.debug.print("\n", .{});
        }
        //std.debug.print("\n", .{});

        return rolls < 4;
    }

    fn getAccessibleRolls(self: *Grid) !std.ArrayList(Position) {
        var rolls = try std.ArrayList(Position).initCapacity(self.alloc, self.height * self.width / 2);
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (self.checkLocation(x, y)) {
                    try rolls.append(self.alloc, Position{ .x = x, .y = y });
                }
            }
        }
        return rolls;
    }

    fn removeRolls(self: *Grid, rolls: std.ArrayList(Position)) usize {
        //std.debug.print("Removing available rolls\n", .{});
        var removed: usize = 0;
        for (rolls.items) |roll| {
            self.removeRoll(roll.x, roll.y);
            removed += 1;
        }
        return removed;
    }

    fn print(self: *Grid) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                std.debug.print("{c}", .{self.getChar(x, y)});
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const f = try std.fs.cwd().openFile("input.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var grid = try Grid.initFromReader(allocator, &reader);
    defer grid.deinit();

    //grid.print();
    var removed: usize = 0;
    while (true) {
        var availableRolls = try grid.getAccessibleRolls();
        defer availableRolls.deinit(grid.alloc);
        if (availableRolls.items.len == 0) {
            break;
        }
        removed += grid.removeRolls(availableRolls);
        //grid.print();
    }

    std.debug.print("Result: {d}\n", .{removed});
}

test "DemoFile" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const f = try std.fs.cwd().openFile("demo.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var grid = try Grid.initFromReader(allocator, &reader);
    defer grid.deinit();

    grid.print();

    try std.testing.expectEqual(false, grid.checkLocation(1, 1));
    try std.testing.expectEqual(true, grid.checkLocation(6, 2));

    // Covers left edge
    try std.testing.expectEqual(true, grid.checkLocation(0, 1));
    try std.testing.expectEqual(false, grid.checkLocation(0, 3));

    // Covers right edge
    try std.testing.expectEqual(true, grid.checkLocation(9, 4));
    try std.testing.expectEqual(false, grid.checkLocation(9, 1));
    // Covers top edge
    try std.testing.expectEqual(true, grid.checkLocation(3, 0));
    try std.testing.expectEqual(false, grid.checkLocation(1, 0));
    // Covers bottom edge
    try std.testing.expectEqual(true, grid.checkLocation(2, 9));
    try std.testing.expectEqual(false, grid.checkLocation(7, 9));

    // Covers corner cases
    try std.testing.expectEqual(false, grid.checkLocation(0, 0));
    try std.testing.expectEqual(true, grid.checkLocation(0, 9));
    try std.testing.expectEqual(false, grid.checkLocation(9, 0));
    try std.testing.expectEqual(false, grid.checkLocation(9, 9));

    var removed: usize = 0;
    while (true) {
        var availableRolls = try grid.getAccessibleRolls();
        defer availableRolls.deinit(grid.alloc);
        if (availableRolls.items.len == 0) {
            break;
        }
        removed += grid.removeRolls(availableRolls);
        //grid.print();
    }
    try std.testing.expectEqual(43, removed);
}
