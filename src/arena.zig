// arena.zig
// Wrapper sobre ArenaAllocator. Ideal para fases del compilador:
// allocás libremente y liberás todo de golpe con deinit().
const std = @import("std");

pub const Arena = struct {
    inner: std.heap.ArenaAllocator,

    /// Crea un Arena usando `backing` como allocator base (ej: std.heap.page_allocator).
    pub fn init(backing: std.mem.Allocator) Arena {
        return .{ .inner = std.heap.ArenaAllocator.init(backing) };
    }

    /// Retorna el allocator del arena para pasarlo a funciones.
    pub fn allocator(self: *Arena) std.mem.Allocator {
        return self.inner.allocator();
    }

    /// Libera toda la memoria allocada desde este arena de una vez.
    pub fn deinit(self: *Arena) void {
        self.inner.deinit();
    }

    /// Libera toda la memoria pero mantiene el arena reutilizable.
    pub fn reset(self: *Arena) void {
        _ = self.inner.reset(.free_all);
    }
};

test "arena" {
    var a = Arena.init(std.testing.allocator);
    defer a.deinit();

    const alloc = a.allocator();
    const buf = try alloc.alloc(u8, 64);
    @memset(buf, 'x');
    try std.testing.expectEqual(@as(usize, 64), buf.len);
    // no hace falta free individual — deinit() libera todo
}