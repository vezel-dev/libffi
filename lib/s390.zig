// SPDX-License-Identifier: MIT

const default = @import("default.zig");

pub const have_complex_type = true;

pub const Abi = default.Abi;

pub const Function = default.Function(Abi);

pub const Closure = default.Closure(Function, 32);
