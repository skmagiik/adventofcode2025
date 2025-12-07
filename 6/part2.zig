const std = @import("std");

const Operands = enum {
    Unknown,
    Add,
    Multiply,
};

const MathProblem = struct {
    values: [4]usize,
    values_added: u8,
    problem_size: u8,
    operand: Operands,

    fn init(problem_size: u8) MathProblem {
        return .{
            .operand = Operands.Unknown,
            .problem_size = problem_size,
            .values = [4]usize{ 0, 0, 0, 0 },
            .values_added = 0,
        };
    }

    fn solve(self: *MathProblem) !usize {
        if (self.values_added != self.problem_size) {
            return error.IncompleteValueSet;
        }
        //std.debug.print("Problem size {d}\n", .{self.problem_size});
        switch (self.operand) {
            Operands.Add => {
                var sum: usize = 0;
                for (0..self.problem_size) |i| {
                    //std.debug.print("Add {d}:{d}\n", .{ i, self.values[i] });
                    sum += self.values[i];
                }
                return sum;
            },
            Operands.Multiply => {
                var total: usize = 1;
                for (0..self.problem_size) |i| {
                    //std.debug.print("Mult by {d}:{d}\n", .{ i, self.values[i] });
                    total *= self.values[i];
                }
                return total;
            },
            Operands.Unknown => {
                return error.UnknownOperand;
            },
        }
    }

    fn addValue(self: *MathProblem, value: usize) void {
        //std.debug.print("attempt to add {d}\n", .{value});
        if (self.values_added >= self.problem_size) {
            return;
        }
        self.values[self.values_added] = value;
        self.values_added += 1;
    }

    fn getValue(_: *MathProblem) usize {
        return 0;
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

    var problems = try std.ArrayList(MathProblem).initCapacity(alloc, 1024);
    defer problems.deinit(alloc);

    var lines = try std.ArrayList([]u8).initCapacity(alloc, 4);
    defer lines.deinit(alloc);

    while (true) {
        const line = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        try lines.append(alloc, line);
    }

    const width: usize = lines.items[0].len;
    const height: usize = lines.items.len;
    //std.debug.print("Width: {d}\n", .{width});
    //std.debug.print("Height: {d}\n", .{height});
    var x: usize = width - 1;
    var problem = MathProblem.init(4); // init with 4 since it could be less but not more
    var sum: usize = 0;
    while (true) {
        var value_str = [4]u8{ ' ', ' ', ' ', ' ' };
        for (0..height - 1) |y| {
            const index: usize = getSeekIdx(width, x, y);
            //std.debug.print("{d},{d} => {x}\n", .{ x, y, index });
            try reader.seekTo(index);
            value_str[y] = (try reader.interface.peek(1))[0];

            //std.debug.print("{s}\n", .{value_str});
        }
        if (std.mem.eql(u8, &value_str, "    ")) {
            if (x == 0) {
                break;
            } else {
                x -= 1;
            }
            continue;
        }
        const value = try std.fmt.parseInt(usize, std.mem.trim(u8, &value_str, " "), 10);
        problem.addValue(value);

        const index: usize = getSeekIdx(width, x, height - 1);
        //std.debug.print("{d},{d} => {x}\n", .{ x, height - 1, index });
        try reader.seekTo(index);
        const c: u8 = (try reader.interface.take(1))[0];
        //std.debug.print("{c}\n", .{c});
        switch (c) {
            '+' => {
                problem.problem_size = problem.values_added;
                problem.operand = Operands.Add;
            },
            '*' => {
                problem.problem_size = problem.values_added;
                problem.operand = Operands.Multiply;
            },
            ' ' => {}, // go to next number or skip empty line
            else => {
                return error.UnexpectedChar;
            },
        }

        //std.debug.print("Problem: {any}\n", .{problem});
        if (problem.operand != Operands.Unknown) {
            const solution = try problem.solve();
            //std.debug.print("solution: {d}\n", .{solution});
            sum += solution;

            // if (problem.operand == Operands.Multiply) {
            //     return;
            // }
            problem = MathProblem.init(4); // init with 4 since it could be less but not more
        }

        if (x == 0) {
            break;
        } else {
            x -= 1;
        }
    }

    std.debug.print("Result: {d}\n", .{sum});
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

    var problems = try std.ArrayList(MathProblem).initCapacity(alloc, 1024);
    defer problems.deinit(alloc);

    var lines = try std.ArrayList([]u8).initCapacity(alloc, 4);
    defer lines.deinit(alloc);

    while (true) {
        const line = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        try lines.append(alloc, line);
    }

    const width: usize = lines.items[0].len;
    const height: usize = lines.items.len;
    std.debug.print("Width: {d}\n", .{width});
    std.debug.print("Height: {d}\n", .{height});
    var x: usize = width - 1;
    var problem = MathProblem.init(4); // init with 4 since it could be less but not more
    var sum: usize = 0;
    while (true) {
        var value_str = [4]u8{ ' ', ' ', ' ', ' ' };
        for (0..height - 1) |y| {
            const index: usize = getSeekIdx(width, x, y);
            std.debug.print("{d},{d} => {x}\n", .{ x, y, index });
            try reader.seekTo(index);
            value_str[y] = (try reader.interface.peek(1))[0];

            std.debug.print("{s}\n", .{value_str});
        }
        if (std.mem.eql(u8, &value_str, "    ")) {
            if (x == 0) {
                break;
            } else {
                x -= 1;
            }
            continue;
        }
        const value = try std.fmt.parseInt(usize, std.mem.trim(u8, &value_str, " "), 10);
        problem.addValue(value);

        const index: usize = getSeekIdx(width, x, height - 1);
        std.debug.print("{d},{d} => {x}\n", .{ x, height - 1, index });
        try reader.seekTo(index);
        const c: u8 = (try reader.interface.take(1))[0];
        std.debug.print("{c}\n", .{c});
        switch (c) {
            '+' => {
                problem.problem_size = problem.values_added;
                problem.operand = Operands.Add;
            },
            '*' => {
                problem.problem_size = problem.values_added;
                problem.operand = Operands.Multiply;
            },
            ' ' => {}, // go to next number or skip empty line
            else => {
                return error.UnexpectedChar;
            },
        }

        std.debug.print("Problem: {any}\n", .{problem});
        if (problem.operand != Operands.Unknown) {
            const solution = try problem.solve();
            std.debug.print("solution: {d}\n", .{solution});
            sum += solution;

            problem = MathProblem.init(4); // init with 4 since it could be less but not more
        }

        if (x == 0) {
            break;
        } else {
            x -= 1;
        }
    }

    try std.testing.expectEqual(3263827, sum);
}
