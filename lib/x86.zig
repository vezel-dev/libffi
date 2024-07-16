// SPDX-License-Identifier: MIT

const builtin = @import("builtin");

const default = @import("default.zig");

pub const have_complex_type = true;

const arg_longlong = r: {
    if (builtin.cpu.arch == .x86_64) {
        if (builtin.os.tag == .windows) {
            break :r true;
        }

        switch (builtin.abi) {
            .gnux32, .muslx32 => break :r true,
            else => {},
        }
    }

    break :r false;
};

pub const uarg = if (arg_longlong) c_ulonglong else c_ulong;
pub const sarg = if (arg_longlong) c_longlong else c_long;

pub const Abi = if (builtin.cpu.arch == .x86_64 and builtin.os.tag == .windows) enum(i32) {
    win64 = 1,
    gnuw64 = 2,
    _,

    pub const default: Abi = if (builtin.abi == .msvc) .win64 else .gnuw64;
} else if (builtin.cpu.arch == .x86_64) enum(i32) {
    unix64 = 2,
    win64 = 3,
    gnuw64 = 4,
    _,

    pub const efi64: Abi = .efi64;
    pub const default: Abi = .unix64;
} else if (builtin.cpu.arch == .x86 and builtin.os.tag == .windows) enum(i32) {
    sysv = 1,
    stdcall = 2,
    thiscall = 3,
    fastcall = 4,
    ms_cdecl = 5,
    pascal = 6,
    register = 7,
    _,

    pub const default: Abi = .ms_cdecl;
} else if (builtin.cpu.arch == .x86) enum(i32) {
    sysv = 1,
    thiscall = 3,
    fastcall = 4,
    stdcall = 5,
    pascal = 6,
    register = 7,
    ms_cdecl = 8,
    _,

    pub const default: Abi = .sysv;
};

pub const Function = default.Function(Abi);
