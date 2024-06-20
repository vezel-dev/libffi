// SPDX-License-Identifier: MIT

const default = @import("default.zig");

pub const Abi = enum(i32) {
    arcompact = 1,
    _,

    pub const default: Abi = .arcompact;
};

pub const Function = default.Function(Abi);

pub const Closure = default.Closure(Function, 12);
