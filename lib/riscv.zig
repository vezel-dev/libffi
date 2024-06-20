// SPDX-License-Identifier: MIT

const default = @import("default.zig");
const ffi = @import("ffi.zig");
const function = @import("function.zig");

pub const Abi = default.Abi;

pub const Function = extern struct {
    abi: Abi,
    param_count: c_uint,
    param_types: ?[*]*ffi.Type,
    return_type: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    _private1: c_uint,
    _private2: c_uint,

    pub const prepare = function.prepare;

    pub const prepareVarArgs = function.prepareVarArgs;

    pub const call = function.call;
};

pub const Closure = default.Closure(Function, 24);
