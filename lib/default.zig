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
        nargs: c_uint,
        arg_types: ?[*]*ffi.Type,
        rtype: *ffi.Type,
        bytes: c_uint,
        flags: c_uint,

        pub usingnamespace @import("function.zig");
    };
}
