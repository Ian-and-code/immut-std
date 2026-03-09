// json.zig
// Wrapper sobre std.json para leer/escribir JSON (usado por imacros).
const std = @import("std");
const Allocator = std.mem.Allocator;
const fs = @import("fs.zig");

/// Parsea JSON desde un slice. El caller llama a parsed.deinit() al terminar.
pub fn parse(comptime T: type, allocator: Allocator, data: []const u8) !std.json.Parsed(T) {
    return std.json.parseFromSlice(T, allocator, data, .{ .ignore_unknown_fields = true });
}

/// Parsea JSON desde un archivo. El caller llama a parsed.deinit() al terminar.
pub fn parseFile(comptime T: type, allocator: Allocator, path: []const u8) !std.json.Parsed(T) {
    const data = try fs.readFile(allocator, path);
    defer allocator.free(data);
    return parse(T, allocator, data);
}

/// Serializa `value` a JSON y lo escribe en `path`.
pub fn writeFile(allocator: Allocator, path: []const u8, value: anytype) !void {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    try std.json.stringify(value, .{ .whitespace = .indent_2 }, buf.writer());
    try fs.writeFile(path, buf.items);
}

/// Serializa `value` a un string JSON. El caller libera la memoria.
pub fn toString(allocator: Allocator, value: anytype) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    errdefer buf.deinit();
    try std.json.stringify(value, .{}, buf.writer());
    return buf.toOwnedSlice();
}

test "json round-trip" {
    const alloc = std.testing.allocator;

    const MyStruct = struct { name: []const u8, value: u32 };
    const original = MyStruct{ .name = "test", .value = 42 };

    const serialized = try toString(alloc, original);
    defer alloc.free(serialized);

    const parsed = try parse(MyStruct, alloc, serialized);
    defer parsed.deinit();

    try std.testing.expectEqualStrings("test", parsed.value.name);
    try std.testing.expectEqual(@as(u32, 42), parsed.value.value);
}