const std = @import("std");

// TODO: https://github.com/ziglang/zig/pull/22907
const manifest: struct {
    name: enum { libffi },
    fingerprint: u64,
    version: []const u8,
    minimum_zig_version: []const u8,
    paths: []const []const u8,
    dependencies: struct {},
} = @import("build.zig.zon");
const version = std.SemanticVersion.parse(manifest.version) catch unreachable;

pub fn build(b: *std.Build) anyerror!void {
    // TODO: https://github.com/ziglang/zig/pull/23239
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link binaries statically or dynamically");
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const strip = b.option(bool, "strip", "Omit debug information in binaries");
    const code_model = b.option(std.builtin.CodeModel, "code-model", "Assume a particular code model") orelse .default;
    const valgrind = b.option(bool, "valgrind", "Enable Valgrind client requests");

    const check_tls = b.step("check", "Run source code checks");
    const fmt_tls = b.step("fmt", "Fix source code formatting");
    const test_tls = b.step("test", "Build and run tests");

    const fmt_paths = &[_][]const u8{
        "lib",
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

    const ffi_mod = b.addModule("ffi", .{
        .root_source_file = b.path(b.pathJoin(&.{ "lib", "ffi.zig" })),
        .link_libc = true, // libffi requires libc.
        .single_threaded = false, // libffi requires libpthread.
        // Inherit other options from consumers of the module.
    });

    const ffi_lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true, // libffi requires libc.
        .single_threaded = false, // libffi requires libpthread.
        .strip = strip,
        .code_model = code_model,
    });

    const cflags = &[_][]const u8{"-fexceptions"};

    ffi_lib_mod.addCSourceFiles(.{
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

    const arch_name, const arch_target, const arch_sources: []const []const u8 =
        switch (t.cpu.arch) {
            .aarch64, .aarch64_be => blk: {
                // The assembly files are only usable with MSVC tooling.
                if (t.os.tag == .windows)
                    @panic("No compatible assembly files for aarch64-windows-gnu.");

                break :blk .{
                    "aarch64",
                    "AARCH64",
                    &.{
                        "ffi.c",
                        "sysv.S",
                    },
                };
            },
            .arc => .{
                "arc",
                "ARC",
                &.{
                    "ffi.c",
                    "sysv.S",
                },
            },
            .arm, .armeb => blk: {
                // The assembly files are only usable with MSVC tooling.
                if (t.os.tag == .windows)
                    @panic("No compatible assembly files for arm-windows-gnu.");

                break :blk .{
                    "arm",
                    "ARM",
                    &.{
                        "ffi.c",
                        "sysv.S",
                    },
                };
            },
            .csky => .{
                "csky",
                "CSKY",
                &.{
                    "ffi.c",
                    "sysv.S",
                },
            },
            .loongarch64 => .{
                "loongarch64",
                "LOONGARCH64",
                &.{
                    "ffi.c",
                    "sysv.S",
                },
            },
            .m68k => .{
                "m68k",
                "M68K",
                &.{
                    "ffi.c",
                    "sysv.S",
                },
            },
            .mips, .mipsel, .mips64, .mips64el => .{
                "mips",
                "MIPS",
                &.{
                    "ffi.c",
                    "n32.S",
                    "o32.S",
                },
            },
            .powerpc, .powerpcle, .powerpc64, .powerpc64le => .{
                "powerpc",
                switch (t.os.tag) {
                    .freebsd, .netbsd, .openbsd => "POWERPC_FREEBSD",
                    .aix => "POWERPC_AIX",
                    else => if (t.os.tag.isDarwin()) "POWERPC_DARWIN" else "POWERPC",
                },
                &switch (t.os.tag) {
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
                    else => if (t.os.tag.isDarwin()) .{
                        "darwin.S",
                        "darwin_closure.S",
                        "ffi_darwin.c",
                    } else .{
                        "ffi.c",
                        "ffi_linux64.c",
                        "ffi_sysv.c",
                        "linux64.S",
                        "linux64_closure.S",
                        "ppc_closure.S",
                        "sysv.S",
                    },
                },
            },
            .riscv32, .riscv64 => .{
                "riscv",
                "RISCV",
                &.{
                    "ffi.c",
                    "sysv.S",
                },
            },
            .s390x => .{
                "s390",
                "S390",
                &.{
                    "ffi.c",
                    "sysv.S",
                },
            },
            .sparc, .sparc64 => .{
                "sparc",
                "SPARC",
                &.{
                    "ffi.c",
                    "ffi64.c",
                    "v8.S",
                    "v9.S",
                },
            },
            .x86 => .{
                "x86",
                switch (t.os.tag) {
                    .freebsd, .openbsd => "X86_FREEBSD",
                    .windows => "X86_WIN32",
                    else => if (t.os.tag.isDarwin()) "X86_DARWIN" else "X86",
                },
                &.{
                    "ffi.c",
                    "sysv.S",
                },
            },
            .x86_64 => .{
                "x86",
                if (t.os.tag == .windows) "X86_WIN64" else "X86_64",
                &if (t.os.tag == .windows) .{
                    "ffiw64.c",
                    "win64.S",
                } else if (t.abi == .gnux32 or t.abi == .muslx32) .{
                    "ffi64.c",
                    "unix64.S",
                } else .{
                    "ffi64.c",
                    "ffiw64.c",
                    "unix64.S",
                    "win64.S",
                },
            },
            .xtensa => .{
                "xtensa",
                "XTENSA",
                &.{
                    "ffi.c",
                    "sysv.S",
                },
            },
            else => @panic("This target is not supported by libffi."),
        };

    ffi_lib_mod.addCSourceFiles(.{
        .root = b.path(b.pathJoin(&.{ "src", arch_name })),
        .files = arch_sources,
        .flags = cflags,
    });

    inline for (.{ "include", "src", b.pathJoin(&.{ "src", arch_name }) }) |inc|
        ffi_lib_mod.addIncludePath(b.path(inc));

    const double_size = t.cTypeByteSize(.double);
    const long_double_size = t.cTypeByteSize(.longdouble);

    const long_double_variant = switch (t.os.tag) {
        .freebsd, .netbsd, .openbsd => t.cpu.arch == .powerpc,
        .linux => t.cpu.arch.isPowerPC(),
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

    // We only need to substitute a few `@...@` variables in this file, so treat it as CMake-style.
    const ffi_h = b.addConfigHeader(.{
        .style = .{ .cmake = b.path(b.pathJoin(&.{ "include", "ffi.h.in" })) },
        .include_path = "ffi.h",
    }, .{
        .FFI_EXEC_TRAMPOLINE_TABLE = t.cpu.arch == .aarch64 and t.os.tag.isDarwin(),
        .HAVE_LONG_DOUBLE = switch (long_double) {
            .false => "0",
            .true => "1",
            .mips64 => "defined(__mips64)",
        },
        .TARGET = arch_target,
        .VERSION = manifest.version,
    });

    // Note that the libffi source code is not as disciplined as we would like about checking some of these macros. For
    // example, there are lots of `#ifdef`s that really should be `#if`s. As a result, when an option should be
    // disabled, we need to not write it at all rather than defining it to zero, hence why we turn many values that seem
    // like they should just be `bool` into optionals.
    const fficonfig_h = b.addConfigHeader(.{
        .style = .{ .autoconf = b.path("fficonfig.zig.h") },
        .include_path = "fficonfig.h",
    }, .{
        .AC_APPLE_UNIVERSAL_BUILD = null, // Not used.
        .EH_FRAME_FLAGS = "a",
        .FFI_DEBUG = null,
        .FFI_EXEC_STATIC_TRAMP = switch (t.os.tag) {
            .linux => if (t.cpu.arch.isArm() or t.cpu.arch.isAARCH64() or t.cpu.arch.isLoongArch() or t.cpu.arch.isPowerPC() or t.cpu.arch == .s390x or t.cpu.arch.isX86()) true else null,
            else => null,
        },
        .FFI_EXEC_TRAMPOLINE_TABLE = if (t.cpu.arch == .aarch64 and t.os.tag.isDarwin()) true else null,
        .FFI_MMAP_EXEC_EMUTRAMP_PAX = null, // TODO: Perhaps make this configurable.
        .FFI_MMAP_EXEC_WRIT = switch (t.os.tag) {
            .freebsd, .openbsd, .solaris => true,
            else => if (t.os.tag.isDarwin() or t.abi.isAndroid()) true else null,
        },
        .FFI_NO_RAW_API = null,
        .FFI_NO_STRUCTS = null,
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
        .HAVE_STRINGS_H = if (t.abi != .msvc and t.abi != .itanium) true else null,
        .HAVE_STRING_H = true,
        .HAVE_SYS_MEMFD_H = null,
        .HAVE_SYS_STAT_H = if (t.abi != .msvc and t.abi != .itanium) true else null,
        .HAVE_SYS_TYPES_H = if (t.abi != .msvc and t.abi != .itanium) true else null,
        .HAVE_UNISTD_H = true,
        .LIBFFI_GNU_SYMBOL_VERSIONING = null,
        .LT_OBJDIR = null, // Not used.
        .PACKAGE = "libffi",
        .PACKAGE_BUGREPORT = "http://github.com/vezel-dev/libffi/issues",
        .PACKAGE_NAME = "libffi",
        .PACKAGE_STRING = "libffi " ++ manifest.version,
        .PACKAGE_TARNAME = "libffi",
        .PACKAGE_URL = "",
        .PACKAGE_VERSION = manifest.version,
        .SIZEOF_DOUBLE = double_size,
        .SIZEOF_LONG_DOUBLE = long_double_size,
        .SIZEOF_SIZE_T = t.ptrBitWidth() / 8,
        .STDC_HEADERS = true,
        .SYMBOL_UNDERSCORE = if ((t.cpu.arch == .x86 and t.os.tag == .windows) or t.os.tag.isDarwin()) true else null,
        .USING_PURIFY = null,
        .VERSION = manifest.version,
        .WORDS_BIGENDIAN = if (t.cpu.arch.endian() == .big) true else null,
    });

    // This is done slightly awkwardly because we need the macro value to be emitted literally, rather than as a string.
    switch (long_double) {
        .false => fficonfig_h.addValues(.{ .HAVE_LONG_DOUBLE = null }),
        .true => fficonfig_h.addValues(.{ .HAVE_LONG_DOUBLE = 1 }),
        .mips64 => fficonfig_h.addValues(.{ .HAVE_LONG_DOUBLE = .@"defined(__mips64)" }),
    }

    inline for (.{ fficonfig_h, ffi_h }) |hdr|
        ffi_lib_mod.addConfigHeader(hdr);

    const lib_step = b.addLibrary(.{
        .linkage = linkage orelse .static,
        .name = "ffi",
        .root_module = ffi_lib_mod,
        .version = version,
    });

    b.installArtifact(lib_step);

    // libffi has historically put its header files directly in the include path, rather than a subdirectory.
    lib_step.installConfigHeader(ffi_h);
    lib_step.installHeader(b.path(b.pathJoin(&.{ "src", arch_name, "ffitarget.h" })), "ffitarget.h");

    const example_mod = b.createModule(.{
        .root_source_file = b.path("example.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
        .code_model = code_model,
        .valgrind = valgrind,
    });

    example_mod.addImport("ffi", ffi_mod);
    example_mod.linkLibrary(lib_step);

    const run_example_step = b.addRunArtifact(b.addExecutable(.{
        .name = "ffi-example",
        .root_module = example_mod,
        .version = version,
    }));

    // Always run the example when requested, even if the binary has not changed.
    run_example_step.has_side_effects = true;

    test_tls.dependOn(&run_example_step.step);
}
