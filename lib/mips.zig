// SPDX-License-Identifier: MIT

const builtin = @import("builtin");

const ffi = @import("ffi.zig");

pub const have_long_double = switch (builtin.cpu.arch) {
    .mips64, .mips64el => switch (builtin.os.tag) {
        .freebsd, .linux, .openbsd => true,
        else => false,
    },
    else => false,
};
pub const have_complex_type = true;

const arg_64 = switch (builtin.cpu.arch) {
    .mips, .mipsel => false,
    .mips64, .mips64el => true,
    else => unreachable,
};

pub const uarg = if (arg_64) u64 else u32;
pub const sarg = if (arg_64) i64 else i32;

pub const Abi = enum(i32) {
    o32 = 1,
    n32 = 2,
    n64 = 3,
    o32_soft_float = 4,
    n32_soft_float = 5,
    n64_soft_float = 6,
    _,

    pub const default: Abi = switch (builtin.cpu.arch) {
        .mips, .mipsel => .o32,
        .mips64, .mips64el => if (builtin.abi == .gnuabi64) .n64 else .n32,
        else => unreachable,
    };
};

pub const Function = extern struct {
    abi: Abi,
    nargs: c_uint,
    arg_types: ?[*]*ffi.Type,
    rtype: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    rstruct_flag: c_uint,
    mips_nfixedargs: c_uint,

    pub usingnamespace @import("function.zig");
};
