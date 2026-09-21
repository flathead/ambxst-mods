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
before enabling one. Ambxst 1.3.0 and newer include runtime translations, so
these packages use the localization service provided by the base project. The
old `community.i18n` package must be removed before enabling current releases.

Use **Sort: Load order** to drag packages into the order in which their patches
should be composed. Dependencies always load before the packages that require
them. When two packages add something at the same place in a file, load order
decides which block comes first.

Calendar support also needs the Python modules listed in its pull request. The
manager checks executable dependencies, but Python import packages remain the
responsibility of the distribution or user environment.

## Move a package into Ambxst core

Each package has one `patches/feature.patch`, generated against the tested
Ambxst revision recorded in its manifest. The manager merges patches three-way
when composing. Load order only matters when two packages add code at the same
location. Inspect the resulting source and run the project checks:

```bash
git switch -c feature/example origin/dev
git apply --check --whitespace=error-all packages/example/patches/feature.patch
git apply packages/example/patches/feature.patch
go test ./...
go vet ./...
```

Run the offscreen QML load check and the feature's manual scenario before opening
or updating a pull request. Once merged, the package can be retired; no adapter
layer or rewrite is required because a mod generation contains ordinary Ambxst
source files.
