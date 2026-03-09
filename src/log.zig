// log.zig
// Logging con niveles y colores ANSI para errores del compilador.
const std = @import("std");
const stderr = std.io.getStdErr().writer();

const Color = struct {
    const reset  = "\x1b[0m";
    const bold   = "\x1b[1m";
    const red    = "\x1b[31m";
    const yellow = "\x1b[33m";
    const cyan   = "\x1b[36m";
    const gray   = "\x1b[90m";
};

pub fn info(comptime fmt: []const u8, args: anytype) void {
    stderr.print(Color.cyan ++ "[info] " ++ Color.reset ++ fmt ++ "\n", args) catch {};
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    stderr.print(Color.yellow ++ "[warn] " ++ Color.reset ++ fmt ++ "\n", args) catch {};
}

pub fn err(comptime fmt: []const u8, args: anytype) void {
    stderr.print(Color.red ++ Color.bold ++ "[error] " ++ Color.reset ++ fmt ++ "\n", args) catch {};
}

pub fn debug(comptime fmt: []const u8, args: anytype) void {
    stderr.print(Color.gray ++ "[debug] " ++ Color.reset ++ fmt ++ "\n", args) catch {};
}

/// Error de compilador con ubicación: archivo, línea, columna.
pub fn compileError(file: []const u8, line: usize, col: usize, comptime fmt: []const u8, args: anytype) void {
    stderr.print(
        Color.bold ++ "{s}:{d}:{d}: " ++ Color.red ++ "error: " ++ Color.reset ++ fmt ++ "\n",
        .{ file, line, col } ++ args,
    ) catch {};
}

/// Igual que compileError pero como warning.
pub fn compileWarn(file: []const u8, line: usize, col: usize, comptime fmt: []const u8, args: anytype) void {
    stderr.print(
        Color.bold ++ "{s}:{d}:{d}: " ++ Color.yellow ++ "warning: " ++ Color.reset ++ fmt ++ "\n",
        .{ file, line, col } ++ args,
    ) catch {};
}