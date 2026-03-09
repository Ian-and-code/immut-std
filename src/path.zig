// path.zig
const std = @import("std");
const Allocator = std.mem.Allocator;
const str = []const u8;

/// Une segmentos con '/' como separador. El caller libera la memoria.
pub fn join(allocator: Allocator, parts: []const str) ![]u8 {
    var total: usize = 0;
    for (parts, 0..) |p, i| {
        total += p.len;
        if (i < parts.len - 1) total += 1;
    }
    const buf = try allocator.alloc(u8, total);
    var off: usize = 0;
    for (parts, 0..) |p, i| {
        @memcpy(buf[off .. off + p.len], p);
        off += p.len;
        if (i < parts.len - 1) {
            buf[off] = '/';
            off += 1;
        }
    }
    return buf;
}

/// Retorna la extensión del archivo incluyendo el punto, o "" si no tiene.
pub fn extension(path: str) str {
    var i: usize = path.len;
    while (i > 0) {
        i -= 1;
        if (path[i] == '.') return path[i..];
        if (path[i] == '/') break;
    }
    return "";
}

/// Retorna el nombre del archivo sin directorios.
pub fn basename(path: str) str {
    var i: usize = path.len;
    while (i > 0) {
        i -= 1;
        if (path[i] == '/') return path[i + 1 ..];
    }
    return path;
}

/// Retorna el directorio padre, o "." si no hay separador.
pub fn dirname(path: str) str {
    var i: usize = path.len;
    while (i > 0) {
        i -= 1;
        if (path[i] == '/') return if (i == 0) "/" else path[0..i];
    }
    return ".";
}

/// Retorna el basename sin extensión.
pub fn stem(path: str) str {
    const base = basename(path);
    const ext = extension(base);
    if (ext.len == 0) return base;
    return base[0 .. base.len - ext.len];
}

/// Retorna true si el path es absoluto.
pub fn isAbsolute(path: str) bool {
    return path.len > 0 and path[0] == '/';
}

test "path" {
    const alloc = std.testing.allocator;

    const j = try join(alloc, &.{ "dist", "cpp", "main.cpp" });
    defer alloc.free(j);
    try std.testing.expectEqualStrings("dist/cpp/main.cpp", j);

    try std.testing.expectEqualStrings(".cpp", extension("main.cpp"));
    try std.testing.expectEqualStrings("main.cpp", basename("dist/cpp/main.cpp"));
    try std.testing.expectEqualStrings("dist/cpp", dirname("dist/cpp/main.cpp"));
    try std.testing.expectEqualStrings("main", stem("dist/cpp/main.cpp"));
}