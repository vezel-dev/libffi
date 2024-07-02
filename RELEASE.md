# Release

Every upstream release should have a corresponding release branch and tag here.
The branch should be named `release/vX.Y.Z`; that is, unlike normal Vezel
convention, even a patch release gets a unique branch. The tag should be named
`vX.Y.Z-B`, where B represents our one-based fork version. B is incremented
whenever we make fixes to the Zig build script or bindings within the same
upstream release cycle, and is reset for any new X/Y/Z combination.

This is the procedure for creating a new release from an upstream release:

1. Run `git checkout -b release/vX.Y.Z vX.Y.Z` to create and switch to the new
   release branch.
2. Cherry-pick our fork's commit range from `master` and resolve any conflicts
   in the process.
3. Adjust the libffi version in [`build.zig`](build.zig) and
   [`build.zig.zon`](build.zig.zon), and then commit the changes.
4. Make sure `zig build` works. Try cross-compiling for any targets that had
   changes in the upstream release.
5. Push the release branch.
6. Run `git tag vX.Y.Z-B -m vX.Y.Z-B -s` to create and sign a release tag, then
   push it.
7. Go to the [releases page](https://github.com/vezel-dev/libffi/releases) to
   create a release from the new tag. The release notes should just be a link to
   the upstream release, such as
   [this one](https://github.com/libffi/libffi/releases/tag/v3.4.6).

(Obviously, step 2 will be easier if `master` is not lagging behind upstream.)

The procedure for creating a release that only includes fixes to the Zig build
script or bindings is simpler: Just commit the fix to the release branch and
then proceed from step 4. Remember to increment the B value!

If something goes wrong, you can run `git tag -d vX.Y.Z-B` and
`git push origin :vX.Y.Z-B` to delete the tag until you resolve the issue(s),
and then repeat whichever steps are necessary.
