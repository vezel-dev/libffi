// SPDX-License-Identifier: MIT

const builtin = @import("builtin");

const default = @import("default.zig");
const ffi = @import("ffi.zig");

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
    linux_align_structs: bool,
    linux_long_double_128: bool,
    linux_long_double_128_ieee: bool,
    linux: bool,
    _pad: i28 = 0,

    pub const default: Abi = .{
        .linux_align_structs = !(builtin.cpu.arch == .powerpc64 and builtin.abi == .gnu),
        .linux_long_double_128 = builtin.abi != .musl,
        .linux_long_double_128_ieee = false,
        .linux = true,
    };
} else packed struct(i32) {
    sysv_soft_float: bool,
    sysv_return_structs: bool,
    sysv_long_double_128_ibm: bool,
    sysv: bool,
    sysv_long_double_128: bool,
    _pad: i27 = 0,

    pub const default: Abi = .{
        .sysv_soft_float = false,
        .sysv_return_structs = switch (builtin.os.tag) {
            .freebsd, .netbsd, .openbsd => true,
            else => false,
        },
        .sysv_long_double_128_ibm = builtin.abi != .musl,
        .sysv = true,
        .sysv_long_double_128 = builtin.abi != .musl,
    };
};

pub const Function = if (!builtin.os.tag.isDarwin() and builtin.os.tag != .aix) extern struct {
    abi: Abi,
    param_count: c_uint,
    param_types: ?[*]*ffi.Type,
    return_type: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    _private1: c_uint,

    pub usingnamespace @import("function.zig");
} else default.Function(Abi);

pub const Closure = default.Closure(Function, if (builtin.cpu.arch == .powerpc64le)
    32
else if (builtin.cpu.arch.isPPC64() or builtin.os.tag == .aix)
    if (builtin.os.tag.isDarwin()) 48 else 24
else
    40);
