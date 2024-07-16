// SPDX-License-Identifier: MIT

const builtin = @import("builtin");

const ffi = @import("ffi.zig");

pub const have_complex_type = builtin.os.tag != .windows;

pub const Abi = enum(i32) {
    sysv = 1,
    vfp = 2,
    _,

    pub const default: Abi = if (builtin.abi.floatAbi() != .soft or builtin.os.tag == .windows) .vfp else .sysv;
};

pub const Function = extern struct {
    abi: Abi,
    nargs: c_uint,
    arg_types: ?[*]*ffi.Type,
    rtype: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    vfp_used: c_int,
    vfp_reg_free: c_ushort,
    vfp_nargs: c_ushort,
    vfp_args: [16]i8,

    pub usingnamespace @import("function.zig");
};
