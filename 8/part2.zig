const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try std.fs.cwd().openFile("input.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var circuits = try std.ArrayList(Circuit).initCapacity(alloc, 1000);

    var next_id: usize = 0;
    while (true) {
        defer next_id += 1;
        const read_line = reader.interface.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        const line = std.mem.trim(u8, read_line, " \n");

        var jb = JunctionBox{ .id = next_id, .x = 0, .y = 0, .z = 0 };
        var lineiter = std.mem.splitScalar(u8, line, ',');
        if (lineiter.next()) |x| {
            //std.debug.print("{s}\n", .{x});
            jb.x = try std.fmt.parseInt(isize, x, 10);
        }
        if (lineiter.next()) |y| {
            //std.debug.print("{s}\n", .{y});
            jb.y = try std.fmt.parseInt(isize, y, 10);
        }
        if (lineiter.next()) |z| {
            //std.debug.print("{s}\n", .{z});
            jb.z = try std.fmt.parseInt(isize, z, 10);
        }

        var circuit = Circuit{ .id = next_id, .junction_boxes = try std.ArrayList(JunctionBox).initCapacity(alloc, 1000) };
        try circuit.junction_boxes.append(alloc, jb);
        try circuits.append(alloc, circuit);
    }

    //std.debug.print("Precalculating connections\n", .{});
    var precalc_connections = try std.ArrayList(Connection).initCapacity(
        alloc,
        (circuits.items.len * (circuits.items.len - 1) / 2),
    );
    defer precalc_connections.deinit(alloc);

    // Just append everything, no inner insert loop
    for (0..circuits.items.len - 1) |idx_1| {
        for (idx_1 + 1..circuits.items.len) |idx_2| {
            const precalc_conn =
                try circuits.items[idx_1].getClosestConnectionBetween(circuits.items[idx_2]);
            try precalc_connections.append(alloc, precalc_conn);
        }
    }

    // Sort once by distance
    std.mem.sort(Connection, precalc_connections.items, {}, connectionLessThan);
    //std.debug.print("Sorted Connections [{d}]:\n", .{precalc_connections.items.len});
    // for (precalc_connections.items) |connection| {
    //     std.debug.print("connection {d} -> {d}: {d}\n", .{ connection.id1, connection.id2, connection.distance });
    // }

    var connections_made: usize = 0;
    var next_test_idx: usize = 0;
    var min_conn = precalc_connections.items[next_test_idx];
    while (circuits.items.len > 1) {
        //std.debug.print("\n\nCircuits:\n", .{});
        // for (circuits.items) |circuit| {
        //     std.debug.print("circuit {d}: {any}\n", .{ circuit.id, circuit.junction_boxes });
        // }
        min_conn = precalc_connections.items[next_test_idx];
        //std.debug.print("closest connection: {any}\n", .{min_conn});
        var c1: usize = 0;
        if (getCircuitIdxByJBID(circuits, min_conn.id1)) |c1idx| {
            c1 = c1idx;
        }
        var c2: usize = 0;
        if (getCircuitIdxByJBID(circuits, min_conn.id2)) |c2idx| {
            c2 = c2idx;
        }
        if (c1 == c2) {
            //std.debug.print("Already in circuit adding connection check count\n", .{});
            next_test_idx += 1;
            connections_made += 1;
            continue;
        }

        if (getCircuitIdxByJBID(circuits, min_conn.id1)) |c1idx| {
            if (getCircuitIdxByJBID(circuits, min_conn.id2)) |c2idx| {
                try circuits.items[c1idx].absorbItemsFrom(alloc, circuits.items[c2idx]);
                circuits.items[c2idx].junction_boxes.deinit(alloc);
                _ = circuits.orderedRemove(c2idx);
                //const old_circuit = circuits.orderedRemove(c2idx);
                //std.debug.print("Removed circuit {d} containing {d}!\n", .{ old_circuit.id, min_conn.id2 });
                connections_made += 1;
            }
        }
        //std.debug.print("\nCircuits: {d}\n", .{circuits.items.len});
        next_test_idx += 1;
    }

    //std.debug.print("Finished initial loop\n", .{});
    //std.debug.print("closest connection: {any}\n", .{min_conn});
    var x1: isize = 1;
    if (circuits.items[0].getJunctionBoxByID(min_conn.id1)) |jb| {
        x1 = jb.x;
    }
    var x2: isize = 1;
    if (circuits.items[0].getJunctionBoxByID(min_conn.id2)) |jb| {
        x2 = jb.x;
    }
    std.debug.print("Result: {any}\n", .{x1 * x2});

    for (circuits.items) |*circuit| {
        circuit.junction_boxes.deinit(alloc);
    }

    circuits.deinit(alloc);
}

const JunctionBox = struct {
    id: usize,
    x: isize,
    y: isize,
    z: isize,
    fn getDistanceBetween(self: *JunctionBox, other: JunctionBox) f64 {
        return std.math.pow(f64, @floatFromInt(other.x - self.x), 2) + std.math.pow(f64, @floatFromInt(other.y - self.y), 2) + std.math.pow(f64, @floatFromInt(other.z - self.z), 2);
    }

    fn getConnectionWith(self: *JunctionBox, cid_self: usize, other: JunctionBox, cid_other: usize) Connection {
        return .{ .id1 = cid_self, .id2 = cid_other, .distance = self.getDistanceBetween(other) };
    }
};

const Connection = struct {
    id1: usize,
    id2: usize,
    distance: f64,
};

fn connectionLessThan(_: void, a: Connection, b: Connection) bool {
    return a.distance < b.distance;
}
const Circuit = struct {
    id: usize,
    junction_boxes: std.ArrayList(JunctionBox),

    fn getClosestConnectionBetween(self: *Circuit, other: Circuit) !Connection {
        if (self.junction_boxes.items.len == 0 or other.junction_boxes.items.len == 0) {
            return error.ZeroLenCircuit;
        }
        var min_conn = self.junction_boxes.items[0].getConnectionWith(self.id, other.junction_boxes.items[0], other.id);
        if (self.id == other.id) {
            min_conn.distance = std.math.floatMax(f64);
        }
        for (0..self.junction_boxes.items.len) |idx_1| {
            for (0..other.junction_boxes.items.len) |idx_2| {
                if (self.id == other.id and idx_1 == idx_2) {
                    continue;
                }
                const next_conn = self.junction_boxes.items[idx_1].getConnectionWith(self.id, other.junction_boxes.items[idx_2], other.id);
                if (next_conn.distance < min_conn.distance) {
                    min_conn = next_conn;
                }
            }
        }
        return min_conn;
    }

    fn getJunctionBoxByID(self: *Circuit, id: usize) ?JunctionBox {
        for (self.junction_boxes.items) |jb| {
            if (jb.id == id) {
                return jb;
            }
        }
        return null;
    }

    fn absorbItemsFrom(self: *Circuit, alloc: std.mem.Allocator, other: Circuit) !void {
        try self.junction_boxes.appendSlice(alloc, other.junction_boxes.items);
    }
};

fn getIdxById(circuits: std.ArrayList(Circuit), id: usize) ?usize {
    for (0..circuits.items.len) |idx| {
        if (circuits.items[idx].id == id) {
            return idx;
        }
    }
    return null;
}

fn getCircuitIdxByJBID(circuits: std.ArrayList(Circuit), id: usize) ?usize {
    for (0..circuits.items.len) |idx| {
        for (0..circuits.items[idx].junction_boxes.items.len) |jb_idx| {
            if (circuits.items[idx].junction_boxes.items[jb_idx].id == id) {
                return idx;
            }
        }
    }
    return null;
}

test "demo.txt" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const f = try std.fs.cwd().openFile("demo.txt", .{});
    defer f.close();

    var reader_buf: [4096]u8 = undefined;
    var reader = f.reader(&reader_buf);

    var circuits = try std.ArrayList(Circuit).initCapacity(alloc, 100);

    var next_id: usize = 0;
    while (true) {
        defer next_id += 1;
        const read_line = reader.interface.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                break;
            },
            else => |e| {
                return e;
            },
        };
        const line = std.mem.trim(u8, read_line, " \n");

        var jb = JunctionBox{ .id = next_id, .x = 0, .y = 0, .z = 0 };
        var lineiter = std.mem.splitScalar(u8, line, ',');
        if (lineiter.next()) |x| {
            //std.debug.print("{s}\n", .{x});
            jb.x = try std.fmt.parseInt(isize, x, 10);
        }
        if (lineiter.next()) |y| {
            //std.debug.print("{s}\n", .{y});
            jb.y = try std.fmt.parseInt(isize, y, 10);
        }
        if (lineiter.next()) |z| {
            //std.debug.print("{s}\n", .{z});
            jb.z = try std.fmt.parseInt(isize, z, 10);
        }

        var circuit = Circuit{ .id = next_id, .junction_boxes = try std.ArrayList(JunctionBox).initCapacity(alloc, 100) };
        try circuit.junction_boxes.append(alloc, jb);
        try circuits.append(alloc, circuit);
    }

    std.debug.print("Precalculating connections\n", .{});
    var precalc_connections = try std.ArrayList(Connection).initCapacity(alloc, (circuits.items.len * (circuits.items.len - 1) / 2));
    defer precalc_connections.deinit(alloc);
    for (0..circuits.items.len - 1) |idx_1| {
        idx2Loop: for (idx_1 + 1..circuits.items.len) |idx_2| {
            std.debug.print("loop 1:\n", .{});
            const precalc_conn = try circuits.items[idx_1].getClosestConnectionBetween(circuits.items[idx_2]);
            for (0..precalc_connections.items.len) |idx_3| {
                std.debug.print("loop 3: {d}\n", .{idx_3});
                if (precalc_conn.distance < precalc_connections.items[idx_3].distance) {
                    try precalc_connections.insert(alloc, idx_3, precalc_conn);
                    continue :idx2Loop;
                }
            }
            try precalc_connections.append(alloc, precalc_conn);
        }
    }
    std.debug.print("Sorted Connections [{d}]:\n", .{precalc_connections.items.len});
    for (precalc_connections.items) |connection| {
        std.debug.print("connection {d} -> {d}: {d}\n", .{ connection.id1, connection.id2, connection.distance });
    }

    var connections_made: usize = 0;
    var next_test_idx: usize = 0;
    while (next_test_idx < precalc_connections.items.len and connections_made < 10) {
        std.debug.print("\n\nCircuits:\n", .{});
        for (circuits.items) |circuit| {
            std.debug.print("circuit {d}: {any}\n", .{ circuit.id, circuit.junction_boxes });
        }
        const min_conn = precalc_connections.items[next_test_idx];
        std.debug.print("closest connection: {any}\n", .{min_conn});
        var c1: usize = 0;
        if (getCircuitIdxByJBID(circuits, min_conn.id1)) |c1idx| {
            c1 = c1idx;
        }
        var c2: usize = 0;
        if (getCircuitIdxByJBID(circuits, min_conn.id2)) |c2idx| {
            c2 = c2idx;
        }
        if (c1 == c2) {
            std.debug.print("Already in circuit adding connection check count\n", .{});
            next_test_idx += 1;
            connections_made += 1;
            continue;
        }

        if (getCircuitIdxByJBID(circuits, min_conn.id1)) |c1idx| {
            if (getCircuitIdxByJBID(circuits, min_conn.id2)) |c2idx| {
                try circuits.items[c1idx].absorbItemsFrom(alloc, circuits.items[c2idx]);
                circuits.items[c2idx].junction_boxes.deinit(alloc);
                const old_circuit = circuits.orderedRemove(c2idx);
                std.debug.print("Removed circuit {d} containing {d}!\n", .{ old_circuit.id, min_conn.id2 });
                connections_made += 1;
            }
        }
        std.debug.print("\nCircuits:\n", .{});
        for (circuits.items) |circuit| {
            std.debug.print("circuit {d}: {any}\n", .{ circuit.id, circuit.junction_boxes });
        }
        next_test_idx += 1;
    }

    var l1: usize = 0;
    var l2: usize = 0;
    var l3: usize = 0;
    for (circuits.items) |circuit| {
        const len = circuit.junction_boxes.items.len;
        if (len > l1) {
            l3 = l2;
            l2 = l1;
            l1 = len;
        } else if (len > l2) {
            l3 = l2;
            l2 = len;
        } else if (len > l3) {
            l3 = len;
        }
    }
    std.debug.print("{d} {d} {d} => {d}\n", .{ l1, l2, l3, l1 * l2 * l3 });
    try std.testing.expectEqual(40, l1 * l2 * l3);

    for (circuits.items) |*circuit| {
        circuit.junction_boxes.deinit(alloc);
    }

    circuits.deinit(alloc);
}
