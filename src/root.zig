// root.zig
// Uso: const std = @import("immut_std.zig");
//      std.fs.readFile(...)
//      std.str.concat(...)

pub const fs      = @import("fs.zig");
pub const str     = @import("string.zig");
pub const path    = @import("path.zig");
pub const process = @import("process.zig");
pub const arena   = @import("arena.zig");
pub const map     = @import("map.zig");
pub const log     = @import("log.zig");
pub const json    = @import("json.zig");