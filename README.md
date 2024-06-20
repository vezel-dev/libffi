# Vezel libffi Fork

This is a friendly fork of [libffi](https://sourceware.org/libffi). The notable
changes made in this fork are the additions of a [Zig](https://ziglang.org)
build script, making it easy to integrate libffi into Zig projects using the Zig
package manager, and a set of idiomatic Zig bindings for libffi's main API.
Additionally, to reduce the package download size, we have removed a large
number of files that are unnecessary when using libffi in a Zig project.
Importantly, **all library source code is identical to upstream**, so in terms
of API/ABI compatibility, using this fork is no different from linking to a
system libffi package.

## Usage

The minimum Zig version supported by this project can be found in the
`minimum_zig_version` field of the [`build.zig.zon`](build.zig.zon) file. We
generally try to track the latest release of Zig. But do note that the `master`
branch may sometimes contain code that only works with a `master` build of Zig.

Please note that the `master` branch is rebased on top of upstream periodically.
**You should use a release tag rather than `master`.** For example:

```bash
zig fetch --save=ffi https://github.com/vezel-dev/libffi/archive/vX.Y.Z-B.tar.gz
# Or, to use Git:
zig fetch --save=ffi git+https://github.com/vezel-dev/libffi.git#vX.Y.Z-B
```

(You can find the latest version on the
[releases page](https://github.com/vezel-dev/libffi/releases).)

Consume the library in your `build.zig`:

```zig
const ffi = b.dependency("ffi", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("ffi", ffi.module("ffi"));

if (b.systemIntegrationOption("ffi", .{})) {
    exe.linkSystemLibrary("ffi");
} else {
    exe.linkLibrary(ffi.artifact("ffi"));
}
```

You can now use the Zig bindings in your code. See [`example.zig`](example.zig)
for basic usage.

## License

This project is licensed under the terms found in [`LICENSE`](LICENSE); this
file is unchanged from upstream.
