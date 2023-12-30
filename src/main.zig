const std = @import("std");
const builtin = @import("builtin");

const WIDTH: usize = 100;
const HEIGHT: usize = 100;
const SIZE: usize = WIDTH * HEIGHT;

const Env = if (builtin.is_test) struct {
    pub fn print(pointer: [*]const u8, length: usize) void {
        _ = length;
        _ = pointer;
    }
} else struct {
    pub extern fn print(pointer: [*]const u8, length: usize) void;
};

fn log(message: []const u8) void {
    return Env.print(message.ptr, message.len);
}

const Cell = enum(u8) {
    Dead = 0,
    Alive = 1,
};

const World = struct {
    cells: [SIZE]Cell = undefined,
};

var WORLD = World{
    .cells = undefined,
};

export fn get_neighbours(row: usize, col: usize) u8 {
    var count: u8 = 0;

    const positions = [8]Cell{
        get_cell((row + HEIGHT - 1) % HEIGHT, (col + WIDTH - 1) % WIDTH),
        get_cell((row + HEIGHT - 1) % HEIGHT, col),
        get_cell((row + HEIGHT - 1) % HEIGHT, (col + 1) % WIDTH),
        get_cell(row, (col + WIDTH - 1) % WIDTH),
        get_cell(row, (col + 1) % WIDTH),
        get_cell((row + 1) % HEIGHT, (col + WIDTH - 1) % WIDTH),
        get_cell((row + 1) % HEIGHT, col),
        get_cell((row + 1) % HEIGHT, (col + 1) % WIDTH),
    };

    for (positions) |cell| {
        if (cell == .Alive) count += 1;
    }

    return count;
}

export fn step() u32 {
    var changed: u32 = 0;
    var new_cells: [SIZE]Cell = undefined;

    for (WORLD.cells, 0..) |cell, index| {
        const x = @mod(index, WIDTH);
        const y = @divFloor(index, WIDTH);
        const neighbours = get_neighbours(x, y);

        switch (cell) {
            .Alive => {
                switch (neighbours) {
                    2, 3 => {
                        new_cells[index] = .Alive;
                    },
                    else => {
                        new_cells[index] = .Dead;
                        changed += 1;
                    },
                }
            },
            .Dead => {
                switch (neighbours) {
                    3 => {
                        new_cells[index] = .Alive;
                        changed += 1;
                    },
                    else => {
                        new_cells[index] = .Dead;
                    },
                }
            },
        }
    }

    WORLD.cells = new_cells;

    return changed;
}

export fn set_cell(x: usize, y: usize, value: Cell) void {
    const index = x + (y * WIDTH);
    WORLD.cells[index] = value;
}

export fn get_cell(x: usize, y: usize) Cell {
    const index = x + (y * WIDTH);
    return WORLD.cells[index];
}

export fn init() void {
    log("Conway's game of life - version 0.1.0 - by https://github.com/Jabolol");
}

export fn reset() void {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }
}

fn dump(width: usize, height: usize) void {
    const total = width * height;

    for (0..total) |index| {
        const cell = WORLD.cells[index];
        if (index % width == 0) {
            std.debug.print("\n", .{});
        }

        switch (cell) {
            .Alive => {
                std.debug.print("X", .{});
            },
            .Dead => {
                std.debug.print(".", .{});
            },
        }

        if (index % width == width - 1) {
            std.debug.print("\n", .{});
        }
    }

    for (0..width) |_| {
        std.debug.print("-", .{});
    }
    std.debug.print("\n", .{});
}

test "get_neighbours 3x3 (8 neighbours)" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    for (5..8) |row| {
        for (5..8) |col| {
            set_cell(row, col, .Alive);
        }
    }

    const result = get_neighbours(6, 6);
    try std.testing.expectEqual(result, 8);
}

test "get_neighbours 3x3 (0 neighbours)" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    set_cell(6, 6, .Alive);

    const result = get_neighbours(6, 6);
    try std.testing.expectEqual(result, 0);
}

test "get_neighbours 3x3 (1 neighbour)" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    set_cell(6, 6, .Alive);
    set_cell(6, 7, .Alive);

    const result = get_neighbours(6, 6);
    try std.testing.expectEqual(result, 1);
}

test "get_neighbours 3x3 left corner (2 neighbours)" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    set_cell(0, 0, .Alive);
    set_cell(0, 1, .Alive);
    set_cell(1, 0, .Alive);

    const result = get_neighbours(0, 0);
    try std.testing.expectEqual(result, 2);
}

test "get_neighbours 3x3 far right corner (2 neighbours)" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    set_cell(WIDTH - 1, 2, .Alive);
    set_cell(WIDTH - 1, 1, .Alive);
    set_cell(WIDTH - 2, 2, .Alive);

    const result = get_neighbours(WIDTH - 1, 2);
    try std.testing.expectEqual(result, 2);
}

test "set_cell + get_cell" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    set_cell(0, 0, .Alive);
    set_cell(0, 1, .Alive);
    set_cell(0, 2, .Alive);

    try std.testing.expectEqual(get_cell(0, 0), .Alive);
    try std.testing.expectEqual(get_cell(0, 1), .Alive);
    try std.testing.expectEqual(get_cell(0, 2), .Alive);
}

test "simple iteration (10 steps)" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    set_cell(0, 1, .Alive);
    set_cell(1, 2, .Alive);
    set_cell(2, 0, .Alive);
    set_cell(2, 1, .Alive);
    set_cell(2, 2, .Alive);

    for (0..10) |_| {
        _ = step();
    }

    try std.testing.expectEqual(get_cell(5, 3), .Alive);
    try std.testing.expectEqual(get_cell(3, 4), .Alive);
    try std.testing.expectEqual(get_cell(4, 4), .Alive);
    try std.testing.expectEqual(get_cell(5, 4), .Alive);
    try std.testing.expectEqual(get_cell(6, 4), .Dead);
}

test "pulsar pattern (10) iterations" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    const coordinates = [48][2]usize{ .{ 10, 12 }, .{ 10, 13 }, .{ 10, 14 }, .{ 10, 18 }, .{ 10, 19 }, .{ 10, 20 }, .{ 12, 10 }, .{ 12, 15 }, .{ 12, 17 }, .{ 12, 22 }, .{ 13, 10 }, .{ 13, 15 }, .{ 13, 17 }, .{ 13, 22 }, .{ 14, 10 }, .{ 14, 15 }, .{ 14, 17 }, .{ 14, 22 }, .{ 15, 12 }, .{ 15, 13 }, .{ 15, 14 }, .{ 15, 18 }, .{ 15, 19 }, .{ 15, 20 }, .{ 17, 12 }, .{ 17, 13 }, .{ 17, 14 }, .{ 17, 18 }, .{ 17, 19 }, .{ 17, 20 }, .{ 18, 10 }, .{ 18, 15 }, .{ 18, 17 }, .{ 18, 22 }, .{ 19, 10 }, .{ 19, 15 }, .{ 19, 17 }, .{ 19, 22 }, .{ 20, 10 }, .{ 20, 15 }, .{ 20, 17 }, .{ 20, 22 }, .{ 22, 12 }, .{ 22, 13 }, .{ 22, 14 }, .{ 22, 18 }, .{ 22, 19 }, .{ 22, 20 } };

    for (coordinates) |coordinate| {
        set_cell(coordinate[0], coordinate[1], .Alive);
    }

    for (0..10) |_| {
        _ = step();
    }

    const expected = [56][2]usize{ .{ 13, 9 }, .{ 19, 9 }, .{ 13, 10 }, .{ 19, 10 }, .{ 13, 11 }, .{ 14, 11 }, .{ 18, 11 }, .{ 19, 11 }, .{ 9, 13 }, .{ 10, 13 }, .{ 11, 13 }, .{ 14, 13 }, .{ 15, 13 }, .{ 17, 13 }, .{ 18, 13 }, .{ 21, 13 }, .{ 22, 13 }, .{ 23, 13 }, .{ 11, 14 }, .{ 13, 14 }, .{ 15, 14 }, .{ 17, 14 }, .{ 19, 14 }, .{ 21, 14 }, .{ 13, 15 }, .{ 14, 15 }, .{ 18, 15 }, .{ 19, 15 }, .{ 13, 17 }, .{ 14, 17 }, .{ 18, 17 }, .{ 19, 17 }, .{ 11, 18 }, .{ 13, 18 }, .{ 15, 18 }, .{ 17, 18 }, .{ 19, 18 }, .{ 21, 18 }, .{ 9, 19 }, .{ 10, 19 }, .{ 11, 19 }, .{ 14, 19 }, .{ 15, 19 }, .{ 17, 19 }, .{ 18, 19 }, .{ 21, 19 }, .{ 22, 19 }, .{ 23, 19 }, .{ 13, 21 }, .{ 14, 21 }, .{ 18, 21 }, .{ 19, 21 }, .{ 13, 22 }, .{ 19, 22 }, .{ 13, 23 }, .{ 19, 23 } };

    for (expected) |coordinate| {
        try std.testing.expectEqual(get_cell(coordinate[0], coordinate[1]), .Alive);
    }
}

test "pulsar pattern (22) iterations" {
    for (WORLD.cells, 0..) |_, index| {
        WORLD.cells[index] = .Dead;
    }

    const coordinates = [48][2]usize{ .{ 10, 12 }, .{ 10, 13 }, .{ 10, 14 }, .{ 10, 18 }, .{ 10, 19 }, .{ 10, 20 }, .{ 12, 10 }, .{ 12, 15 }, .{ 12, 17 }, .{ 12, 22 }, .{ 13, 10 }, .{ 13, 15 }, .{ 13, 17 }, .{ 13, 22 }, .{ 14, 10 }, .{ 14, 15 }, .{ 14, 17 }, .{ 14, 22 }, .{ 15, 12 }, .{ 15, 13 }, .{ 15, 14 }, .{ 15, 18 }, .{ 15, 19 }, .{ 15, 20 }, .{ 17, 12 }, .{ 17, 13 }, .{ 17, 14 }, .{ 17, 18 }, .{ 17, 19 }, .{ 17, 20 }, .{ 18, 10 }, .{ 18, 15 }, .{ 18, 17 }, .{ 18, 22 }, .{ 19, 10 }, .{ 19, 15 }, .{ 19, 17 }, .{ 19, 22 }, .{ 20, 10 }, .{ 20, 15 }, .{ 20, 17 }, .{ 20, 22 }, .{ 22, 12 }, .{ 22, 13 }, .{ 22, 14 }, .{ 22, 18 }, .{ 22, 19 }, .{ 22, 20 } };

    for (coordinates) |coordinate| {
        set_cell(coordinate[0], coordinate[1], .Alive);
    }

    for (0..22) |_| {
        _ = step();
    }

    const expected = [56][2]usize{ .{ 13, 9 }, .{ 19, 9 }, .{ 13, 10 }, .{ 19, 10 }, .{ 13, 11 }, .{ 14, 11 }, .{ 18, 11 }, .{ 19, 11 }, .{ 9, 13 }, .{ 10, 13 }, .{ 11, 13 }, .{ 14, 13 }, .{ 15, 13 }, .{ 17, 13 }, .{ 18, 13 }, .{ 21, 13 }, .{ 22, 13 }, .{ 23, 13 }, .{ 11, 14 }, .{ 13, 14 }, .{ 15, 14 }, .{ 17, 14 }, .{ 19, 14 }, .{ 21, 14 }, .{ 13, 15 }, .{ 14, 15 }, .{ 18, 15 }, .{ 19, 15 }, .{ 13, 17 }, .{ 14, 17 }, .{ 18, 17 }, .{ 19, 17 }, .{ 11, 18 }, .{ 13, 18 }, .{ 15, 18 }, .{ 17, 18 }, .{ 19, 18 }, .{ 21, 18 }, .{ 9, 19 }, .{ 10, 19 }, .{ 11, 19 }, .{ 14, 19 }, .{ 15, 19 }, .{ 17, 19 }, .{ 18, 19 }, .{ 21, 19 }, .{ 22, 19 }, .{ 23, 19 }, .{ 13, 21 }, .{ 14, 21 }, .{ 18, 21 }, .{ 19, 21 }, .{ 13, 22 }, .{ 19, 22 }, .{ 13, 23 }, .{ 19, 23 } };

    for (expected) |coordinate| {
        try std.testing.expectEqual(get_cell(coordinate[0], coordinate[1]), .Alive);
    }
}
