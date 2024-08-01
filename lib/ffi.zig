// SPDX-License-Identifier: MIT

const builtin = @import("builtin");
const std = @import("std");

const target = switch (builtin.cpu.arch) {
    .aarch64, .aarch64_be => @import("aarch64.zig"),
    .arc => @import("arc.zig"),
    .arm, .armeb => @import("arm.zig"),
    .avr => @import("avr32.zig"),
    .csky => @import("csky.zig"),
    .x86, .x86_64 => @import("x86.zig"),
    .loongarch64 => @import("loongarch64.zig"),
    .m68k => @import("m68k.zig"),
    .mips, .mipsel, .mips64, .mips64el => @import("mips.zig"),
    .powerpc, .powerpcle, .powerpc64, .powerpc64le => @import("powerpc.zig"),
    .riscv32, .riscv64 => @import("riscv.zig"),
    .s390x => @import("s390.zig"),
    .sparc, .sparc64 => @import("sparc.zig"),
    .xtensa => @import("xtensa.zig"),
    else => @compileError("This target is not supported by libffi."),
};
const utils = @import("utils.zig");

pub const have_long_double = if (@hasDecl(target, "have_long_double"))
    target.have_long_double
else
    builtin.target.c_type_byte_size(.longdouble) > builtin.target.c_type_byte_size(.double);
pub const have_complex_type = if (@hasDecl(target, "have_complex_type")) target.have_complex_type else false;

pub const uarg = if (@hasDecl(target, "uarg")) target.uarg else c_ulong;
pub const sarg = if (@hasDecl(target, "sarg")) target.sarg else c_long;

pub const Status = enum(i32) {
    ok = 0,
    bad_type_definition = 1,
    bad_abi = 2,
    bad_argument_type = 3,
    _,
};

pub const Error = error{
    OutOfMemory,
    BadTypeDefinition,
    BadAbi,
    BadArgumentType,
    Unexpected,
};

pub const TypeId = if (have_long_double) enum(c_ushort) {
    void = 0,
    int = 1,
    float = 2,
    double = 3,
    long_double = 4,
    uint8 = 5,
    sint8 = 6,
    uint16 = 7,
    sint16 = 8,
    uint32 = 9,
    sint32 = 10,
    uint64 = 11,
    sint64 = 12,
    @"struct" = 13,
    pointer = 14,
    complex = 15,
    _,
} else enum(c_ushort) {
    void = 0,
    int = 1,
    float = 2,
    double = 3,
    uint8 = 5,
    sint8 = 6,
    uint16 = 7,
    sint16 = 8,
    uint32 = 9,
    sint32 = 10,
    uint64 = 11,
    sint64 = 12,
    @"struct" = 13,
    pointer = 14,
    complex = 15,
    _,
};

pub const Type = extern struct {
    size: usize,
    alignment: c_ushort,
    id: TypeId,
    elements: ?[*:null]?*Type,

    pub fn getElementOffsets(self: *Type, abi: Abi, offsets: [*]usize) Error!void {
        return utils.wrap(ffi_get_struct_offsets(self, abi, offsets));
    }
};

pub const types = struct {
    pub const @"void" = &ffi_type_void;
    pub const uint8 = &ffi_type_uint8;
    pub const sint8 = &ffi_type_sint8;
    pub const uint16 = &ffi_type_uint16;
    pub const sint16 = &ffi_type_sint16;
    pub const uint32 = &ffi_type_uint32;
    pub const sint32 = &ffi_type_sint32;
    pub const uint64 = &ffi_type_uint64;
    pub const sint64 = &ffi_type_sint64;
    pub const float = &ffi_type_float;
    pub const double = &ffi_type_double;
    pub const pointer = &ffi_type_pointer;
    pub const long_double = &ffi_type_longdouble;
    pub const complex_float = if (have_complex_type)
        &ffi_type_complex_float
    else
        @compileError("This target does not support complex types.");
    pub const complex_double = if (have_complex_type)
        &ffi_type_complex_double
    else
        @compileError("This target does not support complex types.");
    pub const complex_long_double = if (have_complex_type)
        &ffi_type_complex_longdouble
    else
        @compileError("This target does not support complex types.");

    pub const uchar = &ffi_type_uint8;
    pub const schar = &ffi_type_sint8;
    pub const ushort = &ffi_type_uint16;
    pub const sshort = &ffi_type_sint16;
    pub const uint = switch (builtin.target.c_type_bit_size(.uint)) {
        16 => &ffi_type_uint16,
        32 => &ffi_type_uint32,
        else => unreachable,
    };
    pub const sint = switch (builtin.target.c_type_bit_size(.int)) {
        16 => &ffi_type_sint16,
        32 => &ffi_type_sint32,
        else => unreachable,
    };
    pub const ulong = switch (builtin.target.c_type_bit_size(.ulong)) {
        32 => &ffi_type_uint32,
        64 => &ffi_type_uint64,
        else => unreachable,
    };
    pub const long = switch (builtin.target.c_type_bit_size(.long)) {
        32 => &ffi_type_sint32,
        64 => &ffi_type_sint64,
        else => unreachable,
    };
};

pub const Abi = target.Abi;

pub const Function = target.Function;

pub const Closure = target.Closure;

pub extern var ffi_type_void: Type;
pub extern var ffi_type_uint8: Type;
pub extern var ffi_type_sint8: Type;
pub extern var ffi_type_uint16: Type;
pub extern var ffi_type_sint16: Type;
pub extern var ffi_type_uint32: Type;
pub extern var ffi_type_sint32: Type;
pub extern var ffi_type_uint64: Type;
pub extern var ffi_type_sint64: Type;
pub extern var ffi_type_float: Type;
pub extern var ffi_type_double: Type;
pub extern var ffi_type_pointer: Type;
pub extern var ffi_type_longdouble: Type;
pub extern var ffi_type_complex_float: Type;
pub extern var ffi_type_complex_double: Type;
pub extern var ffi_type_complex_longdouble: Type;

pub extern fn ffi_get_struct_offsets(
    abi: Abi,
    @"type": *Type,
    offsets: [*]usize,
) Status;

pub extern fn ffi_prep_cif(
    function: *Function,
    abi: Abi,
    param_count: c_uint,
    return_type: *Type,
    param_types: ?[*]*Type,
) Status;

pub extern fn ffi_prep_cif_var(
    function: *Function,
    abi: Abi,
    fixed_param_count: c_uint,
    total_param_count: c_uint,
    return_type: *Type,
    param_types: ?[*]*Type,
) Status;

pub extern fn ffi_call(
    function: *Function,
    callee: *const fn () callconv(.C) void,
    result: ?*anyopaque,
    args: ?[*]*anyopaque,
) void;

pub extern fn ffi_closure_alloc(
    size: usize,
    code: **const fn () callconv(.C) void,
) ?*Closure;

pub extern fn ffi_closure_free(
    closure: *Closure,
) void;

pub extern fn ffi_prep_closure_loc(
    closure: *Closure,
    function: *Function,
    wrapper: *const fn (*Function, *anyopaque, ?[*]*anyopaque, ?*anyopaque) callconv(.C) void,
    datum: ?*anyopaque,
    code: *const fn () callconv(.C) void,
) Status;
