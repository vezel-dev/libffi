# Vezel libffi Fork

This is a friendly fork of [libffi](https://sourceware.org/libffi). The notable
change made in this fork is the addition of a [Zig](https://ziglang.org) build
script, making it easy to integrate libffi into Zig projects using the Zig
package manager. Additionally, to reduce the package download size, we have
removed a large number of files that are unnecessary when using libffi in a Zig
project. Importantly, **all library source code is identical to upstream**, so
in terms of API/ABI compatibility, using this fork is no different from linking
to a system libffi package.

## Usage

The minimum Zig version supported by this project can be found in the
`minimum_zig_version` field of the [`build.zig.zon`](build.zig.zon) file. We
generally try to track the latest release of Zig.

Please note that the `master` branch is rebased on top of upstream periodically.
**You should use a release tag rather than `master`.** For example:

```bash
zig fetch --save=ffi https://github.com/vezel-dev/libffi/archive/vX.Y.Z-B.tar.gz
# Or, to use Git:
zig fetch --save=ffi git+https://github.com/vezel-dev/libffi.git#vX.Y.Z-B
```

(You can find the latest libffi version on the
[releases page](https://github.com/vezel-dev/libffi/releases).)

Then, in your `build.zig`:

```zig
const ffi = b.dependency("ffi", .{});
exe.linkLibrary(ffi.artifact("ffi"));

// Or, if you want to be able to integrate with a system package:
if (b.systemIntegrationOption("ffi", .{})) {
    exe.linkSystemLibrary("ffi");
} else {
    const ffi = b.dependency("ffi", .{
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibrary(ffi.artifact("ffi"));
}
```

You can then use the C header in your Zig code:

```zig
const builtin = @import("builtin");
const std = @import("std");
const stdio = @cImport(@cInclude("stdio.h"));
const ffi = @cImport(@cInclude("ffi.h"));

pub fn main() !void {
    std.debug.print("Calling C puts() on {s}.\n", .{builtin.cpu.arch.genericName()});

    var cif: ffi.ffi_cif = undefined;
    var params = [_]?*ffi.ffi_type{
        &ffi.ffi_type_pointer,
    };

    switch (ffi.ffi_prep_cif(
        &cif,
        ffi.FFI_DEFAULT_ABI,
        params.len,
        &ffi.ffi_type_sint32,
        params[0..params.len],
    )) {
        ffi.FFI_OK => {},
        else => |e| return switch (e) {
            ffi.FFI_BAD_TYPEDEF => error.BadTypeDefinition,
            ffi.FFI_BAD_ABI => error.BadAbi,
            ffi.FFI_BAD_ARGTYPE => error.BadArgumentType,
            else => unreachable,
        },
    }

    var result: ffi.ffi_arg = undefined;
    var args = [params.len]?*anyopaque{
        @ptrCast(@constCast(&"Hello World")),
    };

    ffi.ffi_call(&cif, @ptrCast(&stdio.puts), &result, args[0..args.len]);

    if (result == stdio.EOF)
        return error.IOError;
}
```

And finally:

```console
$ zig build run
Calling C puts() on x86.
Hello World
```

Cross-compilation works too:

```console
$ zig build run -fqemu -Dtarget=aarch64-linux
Calling C puts() on aarch64.
Hello World
```

## License

This project is licensed under the terms found in [`LICENSE`](LICENSE); this
file is unchanged from upstream.
