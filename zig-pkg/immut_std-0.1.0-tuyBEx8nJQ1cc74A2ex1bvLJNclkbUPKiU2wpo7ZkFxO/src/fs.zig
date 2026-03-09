// fs.zig - Mini librería de filesystem para Zig
// Uso: @import("fs.zig")

const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

pub const FsError = error{
    NotFound,
    PermissionDenied,
    AlreadyExists,
    IsDirectory,
    NotDirectory,
    DiskFull,
    Unexpected,
};

// ─── Leer archivo completo ────────────────────────────────────────────────────

/// Lee el contenido completo de un archivo. El caller es responsable de liberar la memoria.
pub fn readFile(allocator: Allocator, path: []const u8) ![]u8 {
    const file = fs.cwd().openFile(path, .{}) catch |err| return mapError(err);
    defer file.close();
    const stat_v = try file.stat();
    const buf = try allocator.alloc(u8, stat_v.size);
    errdefer allocator.free(buf);

    const n = try file.readAll(buf);
    return buf[0..n];
}

/// Lee el archivo como líneas. El caller libera el slice y cada línea.
pub fn readLines(allocator: Allocator, path: []const u8) ![][]u8 {
    const content = try readFile(allocator, path);
    defer allocator.free(content);

    var lines = std.ArrayList([]u8).init(allocator);
    errdefer {
        for (lines.items) |l| allocator.free(l);
        lines.deinit();
    }

    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        // omitir línea vacía al final
        if (line.len == 0 and it.peek() == null) break;
        const copy = try allocator.dupe(u8, line);
        try lines.append(copy);
    }

    return lines.toOwnedSlice();
}

// ─── Escribir archivo ─────────────────────────────────────────────────────────

/// Escribe `data` en `path`, creando o sobreescribiendo el archivo.
pub fn writeFile(path: []const u8, data: []const u8) !void {
    const file = fs.cwd().createFile(path, .{ .truncate = true }) catch |err| return mapError(err);
    defer file.close();
    try file.writeAll(data);
}

/// Agrega `data` al final de `path` (crea el archivo si no existe).
pub fn appendFile(path: []const u8, data: []const u8) !void {
    const file = fs.cwd().openFile(path, .{ .mode = .read_write }) catch |e| blk: {
        if (e == error.FileNotFound) {
            break :blk try fs.cwd().createFile(path, .{});
        }
        return mapError(e);
    };
    defer file.close();
    try file.seekFromEnd(0);
    try file.writeAll(data);
}

// ─── Copiar / mover / borrar ──────────────────────────────────────────────────

/// Copia `src` a `dst`.
pub fn copyFile(src: []const u8, dst: []const u8) !void {
    try fs.cwd().copyFile(src, fs.cwd(), dst, .{});
}

/// Renombra / mueve `src` a `dst`.
pub fn moveFile(src: []const u8, dst: []const u8) !void {
    fs.cwd().rename(src, dst) catch |err| return mapError(err);
}

/// Elimina un archivo.
pub fn deleteFile(path: []const u8) !void {
    fs.cwd().deleteFile(path) catch |err| return mapError(err);
}

// ─── Directorios ──────────────────────────────────────────────────────────────

/// Crea un directorio (falla si ya existe).
pub fn mkdir(path: []const u8) !void {
    fs.cwd().makeDir(path) catch |err| return mapError(err);
}

/// Crea un directorio y todos los padres necesarios.
pub fn mkdirAll(path: []const u8) !void {
    fs.cwd().makePath(path) catch |err| return mapError(err);
}

/// Elimina un directorio vacío.
pub fn rmdir(path: []const u8) !void {
    fs.cwd().deleteDir(path) catch |err| return mapError(err);
}

/// Elimina un directorio y todo su contenido recursivamente.
pub fn rmdirAll(path: []const u8) !void {
    var dir = fs.cwd().openDir(path, .{ .iterate = true }) catch |err| return mapError(err);
    defer dir.close();
    try dir.deleteTree(".");
    dir.close();
    try fs.cwd().deleteDir(path);
}

// ─── Listar directorio ────────────────────────────────────────────────────────

pub const DirEntry = struct {
    name: []u8,
    kind: fs.File.Kind,
};

/// Lista entradas de un directorio. El caller libera cada `name` y el slice.
pub fn listDir(allocator: Allocator, path: []const u8) ![]DirEntry {
    var dir = fs.cwd().openDir(path, .{ .iterate = true }) catch |err| return mapError(err);
    defer dir.close();

    var entries = std.ArrayList(DirEntry).init(allocator);
    errdefer {
        for (entries.items) |e| allocator.free(e.name);
        entries.deinit();
    }

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const name = try allocator.dupe(u8, entry.name);
        try entries.append(.{ .name = name, .kind = entry.kind });
    }

    return entries.toOwnedSlice();
}

// ─── Stat / existencia ────────────────────────────────────────────────────────

pub const Stat = struct {
    size: u64,
    kind: fs.File.Kind,
    mtime: i128, // nanoseconds since epoch
};

/// Retorna metadatos de un path.
pub fn stat(path: []const u8) !Stat {
    const file = fs.cwd().openFile(path, .{}) catch |err| return mapError(err);
    defer file.close();
    const s = try file.stat();
    return .{ .size = s.size, .kind = s.kind, .mtime = s.mtime };
}

/// Retorna `true` si el path existe (sea archivo o directorio).
pub fn exists(path: []const u8) bool {
    fs.cwd().access(path, .{}) catch return false;
    return true;
}

/// Retorna `true` si el path existe y es un archivo regular.
pub fn isFile(path: []const u8) bool {
    const s = stat(path) catch return false;
    return s.kind == .file;
}

/// Retorna `true` si el path existe y es un directorio.
pub fn isDir(path: []const u8) bool {
    const s = stat(path) catch return false;
    return s.kind == .directory;
}

// ─── Helper interno ───────────────────────────────────────────────────────────

fn mapError(err: anyerror) FsError {
    return switch (err) {
        error.FileNotFound, error.DirNotFound => FsError.NotFound,
        error.AccessDenied => FsError.PermissionDenied,
        error.PathAlreadyExists => FsError.AlreadyExists,
        error.NotDir => FsError.NotDirectory,
        error.IsDir => FsError.IsDirectory,
        error.NoSpaceLeft => FsError.DiskFull,
        else => FsError.Unexpected,
    };
}

// ─── Tests ────────────────────────────────────────────────────────────────────

test "write, read, delete" {
    const alloc = std.testing.allocator;
    const path = "/tmp/fs_test.txt";

    try writeFile(path, "hola mundo\nsegunda línea\n");
    const content = try readFile(alloc, path);
    defer alloc.free(content);
    try std.testing.expectEqualStrings("hola mundo\nsegunda línea\n", content);

    const lines = try readLines(alloc, path);
    defer {
        for (lines) |l| alloc.free(l);
        alloc.free(lines);
    }
    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expectEqualStrings("hola mundo", lines[0]);

    try deleteFile(path);
    try std.testing.expect(!exists(path));
}

test "append" {
    const path = "/tmp/fs_append.txt";
    try writeFile(path, "línea 1\n");
    try appendFile(path, "línea 2\n");

    const alloc = std.testing.allocator;
    const c = try readFile(alloc, path);
    defer alloc.free(c);
    try std.testing.expectEqualStrings("línea 1\nlínea 2\n", c);
    try deleteFile(path);
}

test "mkdir, exists, rmdir" {
    const dir = "/tmp/fs_test_dir";
    try mkdir(dir);
    try std.testing.expect(isDir(dir));
    try rmdir(dir);
    try std.testing.expect(!exists(dir));
}