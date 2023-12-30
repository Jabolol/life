const std = @import("std");

const ALIVE_CELL = "1";
const ASSET_DIR = "./assets/";
const PATTERN_PATH = "./www/static/patterns.json";

fn parse(
    allocator: std.mem.Allocator,
    filename: []const u8,
) ![][2]usize {
    var path = try std.fs.path.join(allocator, &[_][]const u8{ ASSET_DIR, filename });
    var list = std.ArrayList([2]usize).init(allocator);
    var file = try std.fs.cwd().openFile(path, .{});
    var limit = (try file.stat()).size;
    var result = try file.readToEndAlloc(allocator, limit);

    var row: usize = 0;
    var col: usize = 0;
    var file_it = std.mem.splitSequence(u8, result, "\n");

    while (file_it.next()) |line| {
        var line_it = std.mem.splitSequence(u8, line, " ");
        while (line_it.next()) |char| {
            if (std.mem.eql(u8, char, ALIVE_CELL)) {
                try list.append(.{ col, row });
            }
            row += 1;
        }
        row = 0;
        col += 1;
    }

    return list.toOwnedSlice();
}

fn stringify(
    allocator: std.mem.Allocator,
    filename: []const u8,
    points: [][2]usize,
) ![]const u8 {
    var string = std.ArrayList(u8).init(allocator);
    try std.json.stringify(points, .{}, string.writer());

    return try std.fmt.allocPrint(allocator, "\"{s}\": {s}", .{ filename, string.items });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    var list = std.ArrayList([]const u8).init(allocator);
    var dir = try std.fs.cwd().openIterableDir(ASSET_DIR, .{});
    var walker = try dir.walk(allocator);

    var opt_entry = try walker.next();
    while (opt_entry) |entry| : (opt_entry = try walker.next()) {
        try list.append(try allocator.dupe(u8, entry.basename));
    }

    var elems = std.ArrayList([]const u8).init(allocator);
    for (list.items) |filename| {
        const points = try parse(allocator, filename);
        const item = try stringify(allocator, filename, points);
        try elems.append(item);
    }

    const string = try std.fmt.allocPrint(allocator, "{s}\n", .{elems.items});

    var file = try std.fs.cwd().createFile(PATTERN_PATH, .{ .truncate = true });
    defer file.close();
    try file.writeAll(string);
}
