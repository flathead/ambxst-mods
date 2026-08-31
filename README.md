# Ambxst community mod packages

These packages contain the same source changes as the corresponding Ambxst pull
requests. They can be installed without replacing the base checkout, and their
patches remain suitable for normal upstream review.

## Install a package

The native manager must already be present. In **Settings → Mods**, paste either
a package repository URL or a GitHub package directory URL such as:

```text
https://github.com/flathead/ambxst-mods/tree/main/packages/keyboard-layout-indicator
```

The manager uses a shallow sparse checkout for a GitHub directory, so it does not
download the whole collection. A local clone works too:

```bash
ambxst mods install ./packages/keyboard-layout-indicator
ambxst mods enable community.keyboard-layout-indicator
ambxst reload
```

New packages are installed disabled. Review the manifest, permissions, and patch
before enabling one. UI packages require `community.i18n`; the details pane marks
it as missing, disabled, or ready. **Install required mods** downloads and enables
the dependency after confirmation. It does not enable the selected package.

Use **Sort: Load order** to drag packages into the order in which their patches
should be composed. Dependencies always load before the packages that require
them.

Calendar support also needs the Python modules listed in its pull request. The
manager checks executable dependencies, but Python import packages remain the
responsibility of the distribution or user environment.

## Move a package into Ambxst core

Each package has one `patches/feature.patch`. Independent packages apply directly
to the tested base commit in their manifest. Packages that declare
`community.i18n` are generated against that dependency, so apply the i18n patch
first. Then inspect the resulting source and run the project checks:

```bash
git switch -c feature/example origin/dev
git apply --check --whitespace=error-all packages/i18n/patches/feature.patch
git apply packages/i18n/patches/feature.patch
git apply --check --whitespace=error-all packages/example/patches/feature.patch
git apply packages/example/patches/feature.patch
go test ./...
go vet ./...
```

Run the offscreen QML load check and the feature's manual scenario before opening
or updating a pull request. Once merged, the package can be retired; no adapter
layer or rewrite is required because a mod generation contains ordinary Ambxst
source files.
