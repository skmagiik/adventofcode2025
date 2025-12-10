const std = @import("std");

const Position = struct {
    x: usize,
    y: usize,

    fn getSurfaceArea(self: *Position, other: Position) usize {
        const startPos = Position{ .x = @min(self.x, other.x), .y = @min(self.y, other.y) };
        const endPos = Position{ .x = @max(self.x, other.x), .y = @max(self.y, other.y) };
        const width = @abs(endPos.x - startPos.x) + 1;
        const height = @abs(endPos.y - startPos.y) + 1;
        return width * height;
    }
};

const Grid = struct {
    tiles: std.ArrayList(Position),
    tilehash: std.AutoHashMap(Position, bool),

    fn init(alloc: std.mem.Allocator) !Grid {
        return .{
            .tiles = try std.ArrayList(Position).initCapacity(alloc, 100),
            .tilehash = std.AutoHashMap(Position, bool).init(alloc),
        };
    }

    fn deinit(self: *Grid, alloc: std.mem.Allocator) void {
        self.tiles.deinit(alloc);
        self.tilehash.deinit();
    }

    fn getLowestPositions(self: *Grid) Position {
        var pos = self.tiles.items[0];

        for (self.tiles.items) |tile| {
            if (tile.x < pos.x) {
                pos.x = tile.x;
            }
            if (tile.y < pos.y) {
                pos.y = tile.y;
            }
        }
        return pos;
    }
    fn getHighestPositions(self: *Grid) Position {
        var pos = self.tiles.items[0];

        for (self.tiles.items) |tile| {
            if (tile.x > pos.x) {
                pos.x = tile.x;
            }
            if (tile.y > pos.y) {
                pos.y = tile.y;
            }
        }
        return pos;
    }

    fn render(self: *Grid) void {
        const lowPos = self.getLowestPositions();
        const highPos = self.getHighestPositions();

        for (lowPos.y..highPos.y + 1) |y| {
            for (lowPos.x..highPos.x + 1) |x| {
                if (self.tilehash.get(Position{ .x = x, .y = y })) |_| {
                    std.debug.print("#", .{});
                } else {
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }
    fn renderWithRect(self: *Grid, a: Position, b: Position) void {
        const lowPos = self.getLowestPositions();
        const highPos = self.getHighestPositions();

        const startPos = Position{ .x = @min(a.x, b.x), .y = @min(a.y, b.y) };
        const endPos = Position{ .x = @max(a.x, b.x), .y = @max(a.y, b.y) };

        for (lowPos.y..highPos.y + 1) |y| {
            for (lowPos.x..highPos.x + 1) |x| {
                if (self.tilehash.get(Position{ .x = x, .y = y })) |_| {
                    if ((x == startPos.x or x == endPos.x) and (y == startPos.y or y == endPos.y)) {
                        std.debug.print("0", .{});
                    } else {
                        std.debug.print("#", .{});
                    }
                } else if (x >= startPos.x and x <= endPos.x and y >= startPos.y and y <= endPos.y) {
                    std.debug.print("o", .{});
                } else {
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try std.fs.cwd().openFile("input.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var grid = try Grid.init(alloc);
    defer grid.deinit(alloc);

    while (true) {
        const read_line = std.mem.trim(u8, reader.interface.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        }, " \n");
        //std.debug.print("{s}\n", .{read_line});
        var line_tokens = std.mem.tokenizeAny(u8, read_line, ",");

        var pos: Position = Position{ .x = 0, .y = 0 };
        if (line_tokens.next()) |x| {
            pos.x = try std.fmt.parseInt(usize, x, 10);
        }
        if (line_tokens.next()) |y| {
            pos.y = try std.fmt.parseInt(usize, y, 10);
        }

        try grid.tiles.append(alloc, pos);
        try grid.tilehash.put(pos, true);

        //const line = std.mem.trim(u8, read_line, " \n");
    }
    // for (grid.tiles.items) |tile| {
    //     std.debug.print("{any}\n", .{tile});
    // }
    //grid.render();

    var max_area: usize = 0;
    for (0..grid.tiles.items.len - 1) |idx1| {
        for (1..grid.tiles.items.len) |idx2| {
            //std.debug.print("\n{d} -> {d}\n", .{ idx1, idx2 });
            //std.debug.print("{any} -> {any}\n", .{ grid.tiles.items[idx1], grid.tiles.items[idx2] });
            const area = grid.tiles.items[idx1].getSurfaceArea(grid.tiles.items[idx2]);
            //std.debug.print("area: {d}\n", .{area});
            if (area > max_area) {
                max_area = area;
            }
            //grid.renderWithRect(grid.tiles.items[idx1], grid.tiles.items[idx2]);
        }
    }
    std.debug.print("Result: {d}\n", .{max_area});
}
test "demo.txt" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try std.fs.cwd().openFile("demo.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var grid = try Grid.init(alloc);
    defer grid.deinit(alloc);

    while (true) {
        const read_line = std.mem.trim(u8, reader.interface.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        }, " \n");
        std.debug.print("{s}\n", .{read_line});
        var line_tokens = std.mem.tokenizeAny(u8, read_line, ",");

        var pos: Position = Position{ .x = 0, .y = 0 };
        if (line_tokens.next()) |x| {
            pos.x = try std.fmt.parseInt(usize, x, 10);
        }
        if (line_tokens.next()) |y| {
            pos.y = try std.fmt.parseInt(usize, y, 10);
        }

        try grid.tiles.append(alloc, pos);
        try grid.tilehash.put(pos, true);

        //const line = std.mem.trim(u8, read_line, " \n");
    }
    for (grid.tiles.items) |tile| {
        std.debug.print("{any}\n", .{tile});
    }
    grid.render();

    var max_area: usize = 0;
    for (0..grid.tiles.items.len - 1) |idx1| {
        for (1..grid.tiles.items.len) |idx2| {
            std.debug.print("\n{d} -> {d}\n", .{ idx1, idx2 });
            std.debug.print("{any} -> {any}\n", .{ grid.tiles.items[idx1], grid.tiles.items[idx2] });
            const area = grid.tiles.items[idx1].getSurfaceArea(grid.tiles.items[idx2]);
            std.debug.print("area: {d}\n", .{area});
            if (area > max_area) {
                max_area = area;
            }
            grid.renderWithRect(grid.tiles.items[idx1], grid.tiles.items[idx2]);
        }
    }
    std.debug.print("Result: {d}\n", .{max_area});
    try std.testing.expectEqual(50, max_area);
}
