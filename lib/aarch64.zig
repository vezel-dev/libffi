// SPDX-License-Identifier: MIT

const builtin = @import("builtin");

const closure = @import("closure.zig");
const default = @import("default.zig");
const ffi = @import("ffi.zig");
const function = @import("function.zig");

pub const have_complex_type = builtin.os.tag != .windows;

const arg_longlong = builtin.abi == .gnuilp32 or builtin.os.tag == .windows;

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
    param_count: c_uint,
    param_types: ?[*]*ffi.Type,
    return_type: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    _private1: c_uint,

    pub const prepare = function.prepare;

    pub const prepareVarArgs = function.prepareVarArgs;

    pub const call = function.call;
} else if (builtin.os.tag == .windows) extern struct {
    abi: Abi,
    param_count: c_uint,
    param_types: ?[*]*ffi.Type,
    return_type: *ffi.Type,
    bytes: c_uint,
    flags: c_uint,
    _private1: c_uint,

    pub const prepare = function.prepare;

    pub const prepareVarArgs = function.prepareVarArgs;

    pub const call = function.call;
} else default.Function(Abi);

pub const Closure = if (builtin.os.tag.isDarwin() and builtin.cpu.arch == .aarch64) extern struct {
    trampoline_table: *anyopaque align(8),
    trampoline_table_entry: *anyopaque,
    function: *Function,
    wrapper: *const fn (*Function, *anyopaque, ?[*]*anyopaque, ?*anyopaque) callconv(.C) void,
    datum: ?*anyopaque,

    pub const Code = closure.Code;

    pub const allocCode = closure.allocCode;
} else default.Closure(Function, 24);
