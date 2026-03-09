const std = @import("std");
pub const String = @This();

pub const C_str = [*:0]u8;      // null-terminated para C
pub const str = []const u8;     // slice inmutable
pub const mut_str = []u8;       // slice mutable
pub const char = u8;
pub const C_char = std.os.c_char;
pub const dyn_str = std.ArrayList(u8);
pub fn to_dyn(s:anytype) dyn_str {
    const T =  @TypeOf(s);
    var Rstr: str = undefined;
    if (T == C_str) {
        Rstr = std.mem.span(s);
    } else {
        Rstr = s;
    }
    

    if (T == str or T == C_str or T == mut_str) {
        var string = dyn_str.init(std.heap.page_allocator);
        try string.appendSlice(s);
        return string;
    } else if (T == dyn_str) {
        return s;
    } else {
        @compileError("need a str type to create a dynamic str");
    }
}

pub fn new_dyn(allocator: std.mem.Allocator) dyn_str {
    return dyn_str.init(allocator);
}

/// Comprueba si un slice empieza con otro slice
pub fn startsWith(s: str, prefix: str) bool {
    return s.len >= prefix.len and std.mem.eql(u8, s[0..prefix.len], prefix);
}

/// Convierte un slice a C-string null-terminated
pub fn toCString(allocator: *std.mem.Allocator, slice: str) !C_str {
    const len = slice.len;
    const cstr = try allocator.alloc(char, len + 1);
    std.mem.copy(char, cstr[0..len], slice);
    cstr[len] = 0;
    return cstr;
}

/// Concatena slices dinámicamente
pub fn concat(allocator: *std.mem.Allocator, slices: []const str) !mut_str {
    var total_len: usize = 0;
    for (slices) |s| total_len += s.len;
    const result = try allocator.alloc(char, total_len);
    var offset: usize = 0;
    for (slices) |s| {
        std.mem.copy(char, result[offset..offset + s.len], s);
        offset += s.len;
    }
    return result;
}

/// Compara dos slices
pub fn equal(a: str, b: str) bool {
    return a.len == b.len and std.mem.eql(char, a, b);
}

/// Slice seguro (substring) con límite opcional
pub fn substr(s: str, start: usize, end: ?usize) str {
    const e = end orelse s.len;
    if (start > e or e > s.len) return s[0..0]; // slice vacío si out-of-bounds
    return s[start..e];
}

/// Busca un slice dentro de otro, retorna índice o null
pub fn find(haystack: str, needle: str) ?usize {
    return std.mem.indexOf(u8, haystack, needle) orelse null;
}

/// Convierte a mayúsculas y devuelve nuevo slice
pub fn toUpper(allocator: *std.mem.Allocator, s: str) !mut_str {
    const result = try allocator.alloc(u8, s.len);
    var i: usize = 0;
    for (s) |c| {
        result[i] = if (c >= 'a' and c <= 'z') c - 32 else c;
        i += 1;
    }
    return result;
}

/// Convierte a minúsculas y devuelve nuevo slice
pub fn toLower(allocator: *std.mem.Allocator, s: str) !mut_str {
    const result = try allocator.alloc(u8, s.len);
    var i: usize = 0;
    for (s) |c| {
        result[i] = if (c >= 'A' and c <= 'Z') c + 32 else c;
        i += 1;
    }
    return result;
}

/// Imprime slice a stdout
pub fn print(slice: str) !void {
    try std.io.getStdOut().writer().writeAll(slice);
}

/// Imprime slice + salto de línea
pub fn println(slice: str) !void {
    try std.io.getStdOut().writer().writeAll(slice);
    try std.io.getStdOut().writer().writeAll("\n");
}

pub fn input(allocator: std.mem.Allocator, delimiter: ?char) ![]const u8 {
    if (!delimiter) {
        delimiter = '\n';
    }
    var reader = std.io.getStdIn().reader();
    return try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024);
}
/// Elimina espacios al inicio y final (space, tab, newline, carriage return)
pub fn trim(s: str) str {
    var start: usize = 0;
    var end: usize = s.len;

    while (start < end and isBoundaryChar(s[start])) {
        start += 1;
    }

    while (end > start and isBoundaryChar(s[end - 1])) {
        end -= 1;
    }

    return s[start..end];
}
/// Caracter válido dentro de un identificador: [A-Za-z0-9_]
pub fn isIdenChar(c: char) bool {
    return
        (c >= 'a' and c <= 'z') or
        (c >= 'A' and c <= 'Z') or
        (c >= '0' and c <= '9') or
        (c == '_');
}

/// Comprueba si un slice es un identificador válido
/// Regex equivalente: [\w_][\w\d_]+
pub fn isIden(s: str) bool {
    if (s.len < 1) return false;

    const first = s[0];

    if (!(
        (first >= 'a' and first <= 'z') or
        (first >= 'A' and first <= 'Z') or
        first == '_'
    )) return false;

    for (s[1..]) |c| {
        if (!isIdenChar(c)) return false;
    }

    return true;
}

/// Caracter considerado separador léxico
/// (espacios y whitespace básicos)
pub fn isBoundaryChar(c: char) bool {
    return
        c == ' ' or
        c == '\t' or
        c == '\n' or
        c == '\r' or
        c == 0xB; //vertical tab '\v'
}

/// Comprueba si un slice es completamente boundary
pub fn isBoundary(s: str) bool {
    if (s.len == 0) return false;

    for (s) |c| {
        if (!isBoundaryChar(c)) return false;
    }

    return true;
}

