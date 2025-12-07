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

    fn init(problem_size: u8, startingValue: usize) MathProblem {
        return .{
            .operand = Operands.Unknown,
            .problem_size = problem_size,
            .values = [4]usize{ startingValue, 0, 0, 0 },
            .values_added = 1,
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

    var problems_initialized = false;

    var problems = try std.ArrayList(MathProblem).initCapacity(alloc, 1024);
    defer problems.deinit(alloc);

    for (0..4) |_| {
        const line = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        var tokenizer = std.mem.tokenizeAny(u8, line, " ");
        var token_index: usize = 0;
        while (tokenizer.next()) |token| {
            defer token_index += 1;
            //std.debug.print("{d}:{s} ", .{ token_index, token });
            const value: usize = try std.fmt.parseInt(usize, token, 10);
            if (!problems_initialized) {
                try problems.append(alloc, MathProblem.init(4, value));
            } else {
                problems.items[token_index].addValue(value);
            }
        }
        //std.debug.print("\n", .{});
        problems_initialized = true;
    }
    const line = reader.interface.takeDelimiterExclusive('\n') catch |err| {
        return err;
    };
    var tokenizer = std.mem.tokenizeAny(u8, line, " ");
    var token_index: usize = 0;
    while (tokenizer.next()) |token| {
        defer token_index += 1;
        //std.debug.print("{d}:{s}: ", .{ token_index, token });
        switch (token[0]) {
            '+' => {
                problems.items[token_index].operand = Operands.Add;
            },
            '*' => {
                problems.items[token_index].operand = Operands.Multiply;
            },
            else => {
                //std.debug.print("\nInvalid Operand: {d}\n", .{token[0]});
                return error.InvalidOperand;
            },
        }
    }
    //std.debug.print("\n", .{});

    var sum: usize = 0;
    for (problems.items) |*problem| {
        sum += try problem.solve();
    }
    std.debug.print("Result: {d}\n", .{sum});
}

test "demo.txt" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try std.fs.cwd().openFile("demo.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var problems_initialized = false;

    var problems = try std.ArrayList(MathProblem).initCapacity(alloc, 1024);
    defer problems.deinit(alloc);

    for (0..3) |_| {
        const line = reader.interface.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        var tokenizer = std.mem.tokenizeAny(u8, line, " ");
        var token_index: usize = 0;
        while (tokenizer.next()) |token| {
            defer token_index += 1;
            //std.debug.print("{d}:{s} ", .{ token_index, token });
            const value: usize = try std.fmt.parseInt(usize, token, 10);
            if (!problems_initialized) {
                try problems.append(alloc, MathProblem.init(3, value));
            } else {
                problems.items[token_index].addValue(value);
            }
        }
        //std.debug.print("\n", .{});
        problems_initialized = true;
    }
    const line = reader.interface.takeDelimiterExclusive('\n') catch |err| {
        return err;
    };
    var tokenizer = std.mem.tokenizeAny(u8, line, " ");
    var token_index: usize = 0;
    while (tokenizer.next()) |token| {
        defer token_index += 1;
        //std.debug.print("{d}:{s}: ", .{ token_index, token });
        switch (token[0]) {
            '+' => {
                problems.items[token_index].operand = Operands.Add;
            },
            '*' => {
                problems.items[token_index].operand = Operands.Multiply;
            },
            else => {
                return error.InvalidOperand;
            },
        }
    }
    //std.debug.print("\n", .{});

    var sum: usize = 0;
    for (problems.items) |*problem| {
        //std.debug.print("Problem: {any}\n", .{problem});
        const problem_result = try problem.solve();
        //std.debug.print("Result: {d}\n", .{problem_result});
        sum += problem_result;
    }
    //std.debug.print("Result: {d}\n", .{sum});
    try std.testing.expectEqual(4277556, sum);
}
