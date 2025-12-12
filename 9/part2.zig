const std = @import("std");

const Orientation = enum { Unaligned, Horizontal, Vertical };

const Line = struct {
    a: Position,
    b: Position,
};

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
    lines: std.ArrayList(Line),

    fn init(alloc: std.mem.Allocator) !Grid {
        return .{ .tiles = try std.ArrayList(Position).initCapacity(alloc, 500), .lines = try std.ArrayList(Line).initCapacity(alloc, 500) };
    }

    fn deinit(self: *Grid, alloc: std.mem.Allocator) void {
        self.tiles.deinit(alloc);
        self.lines.deinit(alloc);
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

    fn isRectInside(self: *Grid, a: Position, b: Position) bool {
        const min_x = @min(a.x, b.x);
        const max_x = @max(a.x, b.x);
        const min_y = @min(a.y, b.y);
        const max_y = @max(a.y, b.y);

        for (self.lines.items) |line| {
            //std.debug.print("Line: {d},{d} - {d},{d}\n", .{ line.a.x, line.a.y, line.b.x, line.b.y });
            if (line.a.x == line.b.x) {
                // Vertical
                if (line.a.x > min_x and line.a.x < max_x) {
                    //std.debug.print("Vertical line within horizontal limits\n", .{});
                    if (line.a.y > min_y and line.a.y < max_y) {
                        // Line has a point inside the box
                        //std.debug.print("Line has a point inside the box\n", .{});
                        return false;
                    }
                    if (line.b.y > min_y and line.b.y < max_y) {
                        // Line has a point inside the box
                        //std.debug.print("Line has a point inside the box\n", .{});
                        return false;
                    }
                    if (line.a.y <= min_y and line.b.y >= max_y) {
                        // Line goes through the box completely, but not colinear
                        //std.debug.print("Line goes through the box completely, but not colinear\n", .{});
                        return false;
                    }
                }
            } else if (line.a.y == line.b.y) {
                // Horizontal
                if (line.a.y > min_y and line.a.y < max_y) {
                    //std.debug.print("Horizontal line within vertical limits\n", .{});
                    // Ranges: x[2-9] y[3-7]
                    if (line.a.x > min_x and line.a.x < max_x) {
                        // Line has a point inside the box
                        //std.debug.print("Line has a point inside the box\n", .{});
                        return false;
                    }
                    if (line.b.x > min_x and line.b.x < max_x) {
                        // Line has a point inside the box
                        //std.debug.print("Line has a point inside the box\n", .{});
                        return false;
                    }
                    if (line.a.x <= min_x and line.b.x >= max_x) {
                        // Line goes through the box completely, but not colinear
                        //std.debug.print("Line goes through the box completely, but not colinear\n", .{});
                        return false;
                    }
                }
            }
        }
        return true;
    }

    fn render(self: *Grid) void {
        const lowPos = self.getLowestPositions();
        const highPos = self.getHighestPositions();

        for (lowPos.y - 1..highPos.y + 2) |y| {
            brk: for (lowPos.x - 1..highPos.x + 2) |x| {
                for (self.tiles.items) |tile| {
                    if (tile.x == x and tile.y == y) {
                        std.debug.print("#", .{});
                        continue :brk;
                    }
                }
                std.debug.print(".", .{});
            }
            std.debug.print("\n", .{});
        }
    }
    fn renderWithRect(self: *Grid, a: Position, b: Position) void {
        //const lowPos = self.getLowestPositions();
        const highPos = self.getHighestPositions();

        const startPos = Position{ .x = @min(a.x, b.x), .y = @min(a.y, b.y) };
        const endPos = Position{ .x = @max(a.x, b.x), .y = @max(a.y, b.y) };

        //for (lowPos.y - 1..highPos.y + 1) |y| {
        for (0..highPos.y + 1) |y| {
            //for (lowPos.x - 1..highPos.x + 1) |x| {
            brk: for (0..highPos.x + 1) |x| {
                for (self.tiles.items) |tile| {
                    if (tile.x == x and tile.y == y) {
                        if ((x == startPos.x and y == startPos.y) or (x == endPos.x or y == endPos.y)) {
                            std.debug.print("0", .{});
                        } else if ((x >= startPos.x and x <= endPos.x) and (y >= startPos.y and y <= endPos.y)) {
                            std.debug.print("o", .{});
                        } else {
                            std.debug.print("#", .{});
                        }
                        continue :brk;
                    }
                }

                if ((x >= startPos.x and x <= endPos.x) and (y >= startPos.y and y <= endPos.y)) {
                    std.debug.print("!", .{});
                } else {
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }
};

fn run(filename: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try std.fs.cwd().openFile(filename, .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var grid = try Grid.init(alloc);
    defer grid.deinit(alloc);

    var first_red: ?Position = null;
    var last_red: ?Position = null;
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
        if (first_red == null) {
            first_red = pos;
        }
        if (last_red) |last_tile| {
            // When we add the lines we always add them left-> right and top-> bottom for ease of comparisons later
            if (last_tile.x == pos.x) {
                // Vertical
                if (last_tile.y > pos.y) {
                    try grid.lines.append(alloc, Line{ .a = pos, .b = last_tile });
                } else {
                    try grid.lines.append(alloc, Line{ .a = last_tile, .b = pos });
                }
            } else {
                // Horizontal
                if (last_tile.x > pos.x) {
                    try grid.lines.append(alloc, Line{ .a = pos, .b = last_tile });
                } else {
                    try grid.lines.append(alloc, Line{ .a = last_tile, .b = pos });
                }
            }
        }
        last_red = pos;
    }
    if (first_red) |*t1| {
        //std.debug.print("First red: {any}\n", .{t1});
        if (last_red) |*t2| {
            //std.debug.print("Last red: {any}\n", .{t1});
            if (t2.x == t1.x) {
                // Vertical
                if (t2.y > t1.y) {
                    try grid.lines.append(alloc, Line{ .a = t1.*, .b = t2.* });
                } else {
                    try grid.lines.append(alloc, Line{ .a = t2.*, .b = t1.* });
                }
            } else {
                // Horizontal
                if (t2.x > t1.x) {
                    try grid.lines.append(alloc, Line{ .a = t1.*, .b = t2.* });
                } else {
                    try grid.lines.append(alloc, Line{ .a = t2.*, .b = t1.* });
                }
            }
        }
    }

    //try std.testing.expectEqual(false, try grid.pointInside(Position{ .x = 7, .y = 7 }));

    //grid.render();

    var max_area: usize = 0;
    //std.debug.print("Starting area checks\n", .{});
    for (0..grid.tiles.items.len - 1) |idx1| {
        //std.debug.print("\n{d}/{d}\n", .{ idx1, grid.tiles.items.len - 2 });
        for (1..grid.tiles.items.len) |idx2| {
            //std.debug.print("{d}/{d}\n", .{ idx2, grid.tiles.items.len - 2 });
            //grid.renderWithRect(grid.tiles.items[idx1], grid.tiles.items[idx2]);
            if (!grid.isRectInside(grid.tiles.items[idx1], grid.tiles.items[idx2])) {
                //std.debug.print("RECT OUTSIDE {any} {any}\n", .{ grid.tiles.items[idx1], grid.tiles.items[idx2] });
                continue;
            }
            //std.debug.print("RECT INSIDE {any} {any}\n", .{ grid.tiles.items[idx1], grid.tiles.items[idx2] });
            const area = grid.tiles.items[idx1].getSurfaceArea(grid.tiles.items[idx2]);
            //std.debug.print("area: {d}\n\n", .{area});
            if (area > max_area) {
                max_area = area;
            }
        }
    }
    std.debug.print("\n", .{});
    return max_area;
}

pub fn main() !void {
    const max_area = try run("input.txt");
    std.debug.print("Result: {d}\n", .{max_area});
}

test "demo.txt" {
    const max_area = try run("demo.txt");
    std.debug.print("Result: {d}\n", .{max_area});
    try std.testing.expectEqual(24, max_area);
}
