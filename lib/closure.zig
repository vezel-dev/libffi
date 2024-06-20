// SPDX-License-Identifier: MIT

const ffi = @import("ffi.zig");
const utils = @import("utils.zig");

pub fn Code(Fn: type) type {
    if (@typeInfo(Fn) != .Fn) @compileError("Fn must be a function type.");

    return struct {
        closure: *ffi.Closure,
        trampoline: *const Fn,

        pub fn free(
            self: @This(),
        ) void {
            ffi.ffi_closure_free(self.closure);
        }

        pub fn prepare(
            self: @This(),
            function: *ffi.Function,
            wrapper: *const fn (*ffi.Function, *anyopaque, ?[*]*anyopaque, ?*anyopaque) callconv(.C) void,
            datum: ?*anyopaque,
        ) ffi.Error!void {
            return utils.wrap(
                ffi.ffi_prep_closure_loc(self.closure, function, wrapper, datum, @ptrCast(self.trampoline)),
            );
        }
    };
}

pub fn allocCode(Fn: type) ffi.Error!Code(Fn) {
    var trampoline: *const Fn = undefined;

    return if (ffi.ffi_closure_alloc(@sizeOf(ffi.Closure), @ptrCast(&trampoline))) |closure| .{
        .closure = closure,
        .trampoline = trampoline,
    } else error.OutOfMemory;
}
