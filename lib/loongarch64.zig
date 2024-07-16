// SPDX-License-Identifier: MIT

const builtin = @import("builtin");

const ffi = @import("ffi.zig");

pub const Abi = enum(i32) {
    lp64s = 1,
    lp64f = 2,
    lp64d = 3,
    _,

    // TODO: https://github.com/ziglang/zig/pull/20389
    pub const default: Abi = if (builtin.abi.floatAbi() == .soft) .lp64s else .lp64d;
};

pub const Function = extern struct {
    abi: Abi,
    nargs: c_uint,
    arg_types: ?[*]*ffi.Type,
    rtype: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    loongarch_nfixedargs: c_uint,
    loongarch_unused: c_uint,

    pub usingnamespace @import("function.zig");
};
