// SPDX-License-Identifier: MIT

const ffi = @import("ffi.zig");
const utils = @import("utils.zig");

pub fn prepare(
    self: *ffi.Function,
    abi: ffi.Abi,
    nargs: c_uint,
    rtype: *ffi.Type,
    atypes: ?[*]*ffi.Type,
) ffi.Error!void {
    return utils.wrap(ffi.ffi_prep_cif(self, abi, nargs, rtype, atypes));
}

pub fn prepareVarArgs(
    self: *ffi.Function,
    abi: ffi.Abi,
    nfixedargs: c_uint,
    ntotalargs: c_uint,
    rtype: *ffi.Type,
    atypes: ?[*]*ffi.Type,
) ffi.Error!void {
    return utils.wrap(ffi.ffi_prep_cif_var(self, abi, nfixedargs, ntotalargs, rtype, atypes));
}

pub fn call(
    self: *ffi.Function,
    @"fn": *const fn () callconv(.C) void,
    rvalue: ?*anyopaque,
    avalue: ?[*]*anyopaque,
) void {
    ffi.ffi_call(self, @"fn", rvalue, avalue);
}
