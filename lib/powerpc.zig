// SPDX-License-Identifier: MIT

const builtin = @import("builtin");

const ffi = @import("ffi.zig");
const default = @import("default.zig");

pub const have_long_double = switch (builtin.os.tag) {
    .freebsd, .netbsd, .openbsd => builtin.cpu.arch == .powerpc,
    .linux => true,
    else => false,
};

pub const Abi = if (builtin.os.tag.isDarwin() or builtin.os.tag == .aix) enum(i32) {
    aix = 1,
    darwin = 2,
    _,

    pub const default: Abi = if (builtin.os.tag.isDarwin()) .darwin else .aix;
} else if (builtin.cpu.arch.isPPC64()) packed struct(i32) {
    linux_struct_align: bool,
    linux_long_double_128: bool,
    linux_long_double_ieee128: bool,
    linux: bool,
    _pad: i28 = 0,

    pub const default: Abi = .{
        .linux_struct_align = !(builtin.cpu.arch == .powerpc64 and builtin.abi == .gnu),
        .linux_long_double_128 = builtin.abi != .musl,
        .linux_long_double_ieee128 = false,
        .linux = true,
    };
} else packed struct(i32) {
    sysv_soft_float: bool,
    sysv_struct_ret: bool,
    sysv_ibm_long_double: bool,
    sysv: bool,
    sysv_long_double_128: bool,
    _pad: i27 = 0,

    pub const default: Abi = .{
        .sysv_soft_float = false,
        .sysv_struct_ret = switch (builtin.os.tag) {
            .freebsd, .netbsd, .openbsd => true,
            else => false,
        },
        .sysv_ibm_long_double = builtin.abi != .musl,
        .sysv = true,
        .sysv_long_double_128 = builtin.abi != .musl,
    };
};

pub const Function = if (!builtin.os.tag.isDarwin() and builtin.os.tag != .aix) extern struct {
    abi: Abi,
    nargs: c_uint,
    arg_types: ?[*]*ffi.Type,
    rtype: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    nfixedargs: c_uint,

    pub usingnamespace @import("function.zig");
} else default.Function(Abi);
