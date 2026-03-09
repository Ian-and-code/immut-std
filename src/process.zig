// process.zig
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const RunError = error{ CommandFailed, Unexpected };

pub const Output = struct {
    stdout: []u8,
    stderr: []u8,
    code: u8,
    allocator: Allocator,

    pub fn deinit(self: Output) void {
        self.allocator.free(self.stdout);
        self.allocator.free(self.stderr);
    }
};

/// Ejecuta un comando y devuelve stdout+stderr. El caller llama a output.deinit().
pub fn run(allocator: Allocator, argv: []const []const u8) !Output {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
    });
    const code: u8 = switch (result.term) {
        .Exited => |c| c,
        else => 1,
    };
    return .{
        .stdout = result.stdout,
        .stderr = result.stderr,
        .code = code,
        .allocator = allocator,
    };
}

/// Ejecuta y devuelve solo stdout. Falla si exit code != 0. El caller libera la memoria.
pub fn shell(allocator: Allocator, argv: []const []const u8) ![]u8 {
    const out = try run(allocator, argv);
    defer allocator.free(out.stderr);
    errdefer allocator.free(out.stdout);
    if (out.code != 0) return error.CommandFailed;
    return out.stdout;
}

/// Retorna el valor de una variable de entorno, o null si no existe.
pub fn getEnv(name: []const u8) ?[]const u8 {
    return std.process.getEnvVarOwned(std.heap.page_allocator, name) catch null;
}

/// Retorna los argumentos del proceso. El caller libera con args.deinit().
pub fn args(allocator: Allocator) !std.process.ArgIterator {
    return std.process.argsWithAllocator(allocator);
}

/// Termina el proceso con un código de salida.
pub fn exit(code: u8) noreturn {
    std.process.exit(code);
}