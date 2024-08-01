const std = @import("std");

const version = "3.4.6"; // TODO: https://github.com/ziglang/zig/issues/14531

pub fn build(b: *std.Build) anyerror!void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const check_tls = b.step("check", "Run source code checks");
    const fmt_tls = b.step("fmt", "Fix source code formatting");

    const fmt_paths = &[_][]const u8{
        "build.zig",
        "build.zig.zon",
    };

    check_tls.dependOn(&b.addFmt(.{
        .paths = fmt_paths,
        .check = true,
    }).step);

    fmt_tls.dependOn(&b.addFmt(.{
        .paths = fmt_paths,
    }).step);

    _ = b.addModule("ffi", .{
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "ffi.zig" })),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "ffi",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    b.installArtifact(lib);

    const cflags = &[_][]const u8{"-fexceptions"};

    lib.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{
            "closures.c",
            "java_raw_api.c",
            "prep_cif.c",
            "raw_api.c",
            "tramp.c",
            "types.c",
        },
        .flags = cflags,
    });

    const t = target.result;

    var arch_name: []const u8 = undefined;
    var arch_target: []const u8 = undefined;
    var arch_sources: []const []const u8 = undefined;

    switch (t.cpu.arch) {
        .aarch64, .aarch64_be => {
            // The assembly files are only usable with MSVC tooling.
            if (t.os.tag == .windows) @panic("No compatible assembly files for aarch64-windows-gnu.");

            arch_name = "aarch64";
            arch_target = "AARCH64";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .arc => {
            arch_name = "arc";
            arch_target = "ARC";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .arm, .armeb => {
            // The assembly files are only usable with MSVC tooling.
            if (t.os.tag == .windows) @panic("No compatible assembly files for arm-windows-gnu.");

            arch_name = "arm";
            arch_target = "ARM";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .avr => {
            arch_name = "avr32";
            arch_target = "AVR32";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .csky => {
            arch_name = "csky";
            arch_target = "CSKY";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .x86 => {
            arch_name = "x86";
            arch_target = switch (t.os.tag) {
                .freebsd, .openbsd => "X86_FREEBSD",
                .windows => "X86_WIN32",
                else => if (t.isDarwin()) "X86_DARWIN" else "X86",
            };
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .x86_64 => {
            arch_name = "x86";
            arch_target = if (t.os.tag == .windows) "X86_WIN64" else "X86_64";
            arch_sources = &if (t.os.tag == .windows)
                .{
                    "ffiw64.c",
                    "win64.S",
                }
            else if (t.abi == .gnux32 or t.abi == .muslx32)
                .{
                    "ffi64.c",
                    "unix64.S",
                }
            else
                .{
                    "ffi64.c",
                    "ffiw64.c",
                    "unix64.S",
                    "win64.S",
                };
        },
        .loongarch64 => {
            arch_name = "loongarch64";
            arch_target = "LOONGARCH64";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .m68k => {
            arch_name = "m68k";
            arch_target = "M68K";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .mips, .mipsel, .mips64, .mips64el => {
            arch_name = "mips";
            arch_target = "MIPS";
            arch_sources = &.{
                "ffi.c",
                "n32.S",
                "o32.S",
            };
        },
        .powerpc, .powerpcle, .powerpc64, .powerpc64le => {
            arch_name = "powerpc";
            arch_target = switch (t.os.tag) {
                .freebsd, .netbsd, .openbsd => "POWERPC_FREEBSD",
                .aix => "POWERPC_AIX",
                else => if (t.isDarwin()) "POWERPC_DARWIN" else "POWERPC",
            };
            arch_sources = &switch (t.os.tag) {
                .freebsd, .netbsd, .openbsd => .{
                    "ffi.c",
                    "ffi_sysv.c",
                    "ppc_closure.S",
                    "sysv.S",
                },
                .aix => .{
                    "aix.S",
                    "aix_closure.S",
                    "ffi_darwin.c",
                },
                else => if (t.isDarwin())
                    .{
                        "darwin.S",
                        "darwin_closure.S",
                        "ffi_darwin.c",
                    }
                else
                    .{
                        "ffi.c",
                        "ffi_linux64.c",
                        "ffi_sysv.c",
                        "linux64.S",
                        "linux64_closure.S",
                        "ppc_closure.S",
                        "sysv.S",
                    },
            };
        },
        .riscv32, .riscv64 => {
            arch_name = "riscv";
            arch_target = "RISCV";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .s390x => {
            arch_name = "s390";
            arch_target = "S390";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        .sparc, .sparc64 => {
            arch_name = "sparc";
            arch_target = "SPARC";
            arch_sources = &.{
                "ffi.c",
                "ffi64.c",
                "v8.S",
                "v9.S",
            };
        },
        .xtensa => {
            arch_name = "xtensa";
            arch_target = "XTENSA";
            arch_sources = &.{
                "ffi.c",
                "sysv.S",
            };
        },
        else => @panic("This target is not supported by libffi."),
    }

    lib.addCSourceFiles(.{
        .root = b.path(b.pathJoin(&.{ "src", arch_name })),
        .files = arch_sources,
        .flags = cflags,
    });

    inline for (.{ "include", "src", b.pathJoin(&.{ "src", arch_name }) }) |inc| {
        lib.addIncludePath(b.path(inc));
    }

    const double_size = t.c_type_byte_size(.double);
    const long_double_size = t.c_type_byte_size(.longdouble);

    const long_double_variant = switch (t.os.tag) {
        .freebsd, .netbsd, .openbsd => t.cpu.arch == .powerpc,
        .linux => t.cpu.arch.isPPC() or t.cpu.arch.isPPC64(),
        else => false,
    };
    const long_double: enum {
        false,
        true,
        mips64,
    } = if (t.cpu.arch.isMIPS() and (t.os.tag == .freebsd or t.os.tag == .linux or t.os.tag == .openbsd))
        .mips64
    else if (long_double_variant or long_double_size > double_size)
        .true
    else
        .false;

    // We only need to substitute a few @...@ variables in this file, so treat it as CMake-style.
    const ffi_h = b.addConfigHeader(.{
        .style = .{ .cmake = b.path(b.pathJoin(&.{ "include", "ffi.h.in" })) },
        .include_path = "ffi.h",
    }, .{
        .FFI_EXEC_TRAMPOLINE_TABLE = t.isDarwin() and (t.cpu.arch.isARM() or t.cpu.arch == .aarch64),
        .HAVE_LONG_DOUBLE = switch (long_double) {
            .false => "0",
            .true => "1",
            .mips64 => "defined(__mips64)",
        },
        .TARGET = arch_target,
        .VERSION = version,
    });

    // Note that the libffi source code is not as disciplined as we would like about checking some of these macros.
    // For example, there are lots of `#ifdef`s that really should be `#if`s. As a result, when an option should be
    // disabled, we need to not write it at all rather than defining it to zero, hence why we turn many values that
    // seem like they should just be Booleans into optionals.
    const fficonfig_h = b.addConfigHeader(.{
        .style = .{ .autoconf = b.path("fficonfig.zig.h") },
        .include_path = "fficonfig.h",
    }, .{
        .AC_APPLE_UNIVERSAL_BUILD = null, // Not used.
        .EH_FRAME_FLAGS = "a",
        .FFI_DEBUG = null, // TODO: Perhaps make this configurable.
        .FFI_EXEC_STATIC_TRAMP = switch (t.os.tag) {
            .linux => if (t.cpu.arch.isARM() or t.cpu.arch.isAARCH64() or t.cpu.arch.isX86() or t.cpu.arch == .loongarch32 or t.cpu.arch == .loongarch64) true else null,
            else => null,
        },
        .FFI_EXEC_TRAMPOLINE_TABLE = if (t.isDarwin() and (t.cpu.arch.isARM() or t.cpu.arch == .aarch64)) true else null,
        .FFI_MMAP_EXEC_EMUTRAMP_PAX = null, // TODO: Perhaps make this configurable.
        .FFI_MMAP_EXEC_WRIT = switch (t.os.tag) {
            .freebsd, .openbsd, .solaris => true,
            else => if (t.isDarwin() or t.isAndroid()) true else null,
        },
        .FFI_NO_RAW_API = null, // TODO: Perhaps make this configurable.
        .FFI_NO_STRUCTS = null, // TODO: Perhaps make this configurable.
        .HAVE_ALLOCA_H = if (t.os.tag != .windows) true else null,
        .HAVE_ARM64E_PTRAUTH = null, // TODO: https://github.com/ziglang/fetch-them-macos-headers/issues/28
        .HAVE_AS_CFI_PSEUDO_OP = true,
        .HAVE_AS_REGISTER_PSEUDO_OP = if (t.cpu.arch.isSPARC()) true else null,
        .HAVE_AS_S390_ZARCH = if (t.cpu.arch == .s390x) true else null,
        .HAVE_AS_SPARC_UA_PCREL = true,
        .HAVE_AS_X86_64_UNWIND_SECTION_TYPE = if (t.cpu.arch == .x86_64) true else null,
        .HAVE_AS_X86_PCREL = true,
        .HAVE_DLFCN_H = if (t.os.tag != .windows) true else null,
        .HAVE_HIDDEN_VISIBILITY_ATTRIBUTE = if (t.os.tag != .windows) true else null,
        .HAVE_INTTYPES_H = true,
        .HAVE_LONG_DOUBLE_VARIANT = if (long_double_variant) true else null,
        .HAVE_MEMCPY = true,
        .HAVE_MEMFD_CREATE = if (t.os.tag == .linux) true else null,
        .HAVE_RO_EH_FRAME = true,
        .HAVE_STDINT_H = true,
        .HAVE_STDIO_H = true,
        .HAVE_STDLIB_H = true,
        .HAVE_STRINGS_H = if (t.abi != .msvc) true else null,
        .HAVE_STRING_H = true,
        .HAVE_SYS_MEMFD_H = null,
        .HAVE_SYS_STAT_H = if (t.abi != .msvc) true else null,
        .HAVE_SYS_TYPES_H = if (t.abi != .msvc) true else null,
        .HAVE_UNISTD_H = true,
        .LIBFFI_GNU_SYMBOL_VERSIONING = null,
        .LT_OBJDIR = null, // Not used.
        .PACKAGE = "libffi",
        .PACKAGE_BUGREPORT = "http://github.com/libffi/libffi/issues",
        .PACKAGE_NAME = "libffi",
        .PACKAGE_STRING = "libffi " ++ version,
        .PACKAGE_TARNAME = "libffi",
        .PACKAGE_URL = "",
        .PACKAGE_VERSION = version,
        .SIZEOF_DOUBLE = double_size,
        .SIZEOF_LONG_DOUBLE = long_double_size,
        .SIZEOF_SIZE_T = t.ptrBitWidth() / 8,
        .STDC_HEADERS = true,
        .SYMBOL_UNDERSCORE = if (t.isDarwin() or (t.os.tag == .windows and t.cpu.arch == .x86)) true else null,
        .USING_PURIFY = null, // TODO: Perhaps make this configurable.
        .VERSION = version,
        .WORDS_BIGENDIAN = if (t.cpu.arch.endian() == .big) true else null,
    });

    // This is done slightly awkwardly because we need the macro value to be emitted literally, rather than as a string.
    switch (long_double) {
        .false => fficonfig_h.addValues(.{ .HAVE_LONG_DOUBLE = null }),
        .true => fficonfig_h.addValues(.{ .HAVE_LONG_DOUBLE = 1 }),
        .mips64 => fficonfig_h.addValues(.{ .HAVE_LONG_DOUBLE = .@"defined(__mips64)" }),
    }

    inline for (.{ fficonfig_h, ffi_h }) |h| {
        lib.addConfigHeader(h);
    }

    // libffi has historically put its header files directly in the include path, rather than a subdirectory.
    lib.installConfigHeader(ffi_h);
    lib.installHeader(b.path(b.pathJoin(&.{ "src", arch_name, "ffitarget.h" })), "ffitarget.h");
}
