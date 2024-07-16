// SPDX-License-Identifier: MIT

const builtin = @import("builtin");

const ffi = @import("ffi.zig");
const default = @import("default.zig");

pub const have_complex_type = builtin.os.tag != .windows;

const arg_longlong = builtin.cpu.arch == .aarch64_32 or builtin.os.tag == .windows;

pub const uarg = if (arg_longlong) c_ulonglong else c_ulong;
pub const sarg = if (arg_longlong) c_longlong else c_long;

pub const Abi = enum(i32) {
    sysv = 1,
    win64 = 2,
    _,

    pub const default: Abi = if (builtin.os.tag == .windows) .win64 else .sysv;
};

pub const Function = if (builtin.os.tag.isDarwin()) extern struct {
    abi: Abi,
    nargs: c_uint,
    arg_types: ?[*]*ffi.Type,
    rtype: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    aarch64_nfixedargs: c_uint,

    pub usingnamespace @import("function.zig");
} else if (builtin.os.tag == .windows) extern struct {
    abi: Abi,
    nargs: c_uint,
    arg_types: ?[*]*ffi.Type,
    rtype: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    is_variadic: c_uint,

    pub usingnamespace @import("function.zig");
} else default.Function(Abi);
