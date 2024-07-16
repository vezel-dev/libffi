// SPDX-License-Identifier: MIT

const ffi = @import("ffi.zig");

pub fn wrap(status: ffi.Status) ffi.Error!void {
    return switch (status) {
        .ok => {},
        .bad_type_definition => error.BadTypeDefinition,
        .bad_abi => error.BadAbi,
        .bad_argument_type => error.BadArgumentType,
        _ => error.Unexpected,
    };
}
