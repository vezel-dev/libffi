// SPDX-License-Identifier: MIT

const ffi = @import("ffi.zig");

pub const Abi = enum(i32) {
    sysv = 1,
    _,

    pub const default: Abi = .sysv;
};

pub fn Function(TAbi: type) type {
    return extern struct {
        abi: TAbi,
        param_count: c_uint,
        param_types: ?[*]*ffi.Type,
        return_type: *ffi.Type,
        bytes: c_uint,
        flags: c_uint,

        pub usingnamespace @import("function.zig");
    };
}

pub fn Closure(TFunction: type, size: comptime_int) type {
    return extern struct {
        trampoline: extern union {
            dynamic: [size]c_char,
            static: *anyopaque,
        } align(8),
        function: *TFunction,
        wrapper: *const fn (*TFunction, *anyopaque, ?[*]*anyopaque, ?*anyopaque) callconv(.C) void,
        datum: ?*anyopaque,

        pub usingnamespace @import("closure.zig");
    };
}
