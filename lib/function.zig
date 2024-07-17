// SPDX-License-Identifier: MIT

const ffi = @import("ffi.zig");
const utils = @import("utils.zig");

pub fn prepare(
    self: *ffi.Function,
    abi: ffi.Abi,
    param_count: c_uint,
    param_types: ?[*]*ffi.Type,
    return_type: *ffi.Type,
) ffi.Error!void {
    return utils.wrap(ffi.ffi_prep_cif(self, abi, param_count, return_type, param_types));
}

pub fn prepareVarArgs(
    self: *ffi.Function,
    abi: ffi.Abi,
    fixed_param_count: c_uint,
    var_param_count: c_uint,
    param_types: ?[*]*ffi.Type,
    return_type: *ffi.Type,
) ffi.Error!void {
    return utils.wrap(
        ffi.ffi_prep_cif_var(
            self,
            abi,
            fixed_param_count,
            fixed_param_count + var_param_count,
            return_type,
            param_types,
        ),
    );
}

pub fn call(
    self: *ffi.Function,
    callee: anytype,
    args: ?[*]*anyopaque,
    result: ?*anyopaque,
) void {
    const ty = @typeInfo(@TypeOf(callee));

    switch (ty) {
        .Pointer => |ptr| if (@typeInfo(ptr.child) != .Fn) @compileError("callee must have function pointer type."),
        else => {},
    }

    ffi.ffi_call(self, @ptrCast(callee), result, args);
}
