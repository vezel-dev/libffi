// SPDX-License-Identifier: MIT

const ffi = @import("ffi.zig");
const default = @import("default.zig");

pub const Abi = default.Abi;

pub const Function = extern struct {
    abi: Abi,
    nargs: c_uint,
    arg_types: ?[*]*ffi.Type,
    rtype: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    riscv_nfixedargs: c_uint,
    riscv_unused: c_uint,

    pub usingnamespace @import("function.zig");
};
