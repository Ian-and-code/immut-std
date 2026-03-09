// map.zig
// Wrappers sobre StringHashMap y AutoHashMap con API más cómoda.
const std = @import("std");
const Allocator = std.mem.Allocator;

/// Mapa string → V. El caller llama a deinit() al terminar.
pub fn StrMap(comptime V: type) type {
    return struct {
        inner: std.StringHashMap(V),

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{ .inner = std.StringHashMap(V).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.inner.deinit();
        }

        pub fn put(self: *Self, key: []const u8, value: V) !void {
            try self.inner.put(key, value);
        }

        pub fn get(self: *Self, key: []const u8) ?V {
            return self.inner.get(key);
        }

        pub fn has(self: *Self, key: []const u8) bool {
            return self.inner.contains(key);
        }

        pub fn remove(self: *Self, key: []const u8) bool {
            return self.inner.remove(key);
        }

        pub fn count(self: *Self) usize {
            return self.inner.count();
        }

        pub fn iter(self: *Self) std.StringHashMap(V).Iterator {
            return self.inner.iterator();
        }
    };
}

/// Mapa K → V donde K es cualquier tipo con hash automático.
pub fn Map(comptime K: type, comptime V: type) type {
    return struct {
        inner: std.AutoHashMap(K, V),

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{ .inner = std.AutoHashMap(K, V).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.inner.deinit();
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            try self.inner.put(key, value);
        }

        pub fn get(self: *Self, key: K) ?V {
            return self.inner.get(key);
        }

        pub fn has(self: *Self, key: K) bool {
            return self.inner.contains(key);
        }

        pub fn remove(self: *Self, key: K) bool {
            return self.inner.remove(key);
        }

        pub fn count(self: *Self) usize {
            return self.inner.count();
        }

        pub fn iter(self: *Self) std.AutoHashMap(K, V).Iterator {
            return self.inner.iterator();
        }
    };
}

test "StrMap" {
    var m = StrMap(u32).init(std.testing.allocator);
    defer m.deinit();

    try m.put("foo", 42);
    try std.testing.expectEqual(@as(?u32, 42), m.get("foo"));
    try std.testing.expect(m.has("foo"));
    _ = m.remove("foo");
    try std.testing.expect(!m.has("foo"));
}