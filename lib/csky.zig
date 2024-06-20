// SPDX-License-Identifier: MIT

const default = @import("default.zig");

pub const Abi = default.Abi;

pub const Function = default.Function(Abi);

pub const Closure = default.Closure(Function, 24);
