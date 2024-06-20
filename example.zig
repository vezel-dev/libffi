const builtin = @import("builtin");
const std = @import("std");
const ffi = @import("ffi");

const stdio = @cImport(@cInclude("stdio.h"));

pub fn main() anyerror!void {
    std.debug.print("Calling C puts() on {s}-{s}.\n", .{ @tagName(builtin.cpu.arch), @tagName(builtin.os.tag) });

    var func: ffi.Function = undefined;
    var params = [_]*ffi.Type{
        ffi.types.pointer,
    };

    try func.prepare(.default, params.len, params[0..], ffi.types.sint32);

    var result: ffi.uarg = undefined;
    var args: [params.len]*anyopaque = .{
        @ptrCast(@constCast(&"Hello World")),
    };

    func.call(&stdio.puts, args[0..], &result);

    if (result == stdio.EOF)
        return error.IOError;
}
