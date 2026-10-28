# hmod-build

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

Shared versioning, packaging and release workflow for my hakchi hmods, so every mod is built the same way.

## What every mod gets

- **Version from the git tag only.** Tag `v3.0.0-alpha4` builds version `3.0.0-alpha4`; an untagged build is `3.0.0-alpha4-3-gabc1234` (`git describe`). No `VERSION` file.
- **Fixed file name:** `out/<MOD_ID>.hmod`, no version in it. Hakchi uses the file name as the mod's id, so a versioned name would install every update as a separate mod.
- **The same readme header:** Name, Creator, Category, Version, Built on, Git commit. The body is the mod's own `mod/readme.md`, without its leading `# title` line.
- **A changelog in pre-release readmes:** when the version has a `-` (`3.0.0-alpha4`, or an untagged build), the readme gets a `## Changes since <previous tag>` list of the commit subjects since that tag, so testers see what changed. Stable releases don't get it.
- **A smoke test of the packaged files** (`hmod-check.sh`, run before the hmod is written): the build fails on a shell syntax error in `install`, `uninstall` or any `sh`/`bash`/`ash` script, CRLF line endings in a text file, an ELF binary that isn't 32-bit ARM, or a `*.o`, `.DS_Store`, `Thumbs.db` or `desktop.ini` leftover.
- **A release per `v*` tag** (pre-release when the tag has a `-`), and a rebuild of the [hakchi-repo](https://github.com/DefKorns/hakchi-repo) hub right after.

## Use it in a mod

Add it as a submodule under `vendor/`, checked out at a release tag:

```sh
git submodule add https://github.com/DefKorns/hmod-build.git vendor/hmod-build
git -C vendor/hmod-build checkout v1.2.0
```

`Makefile`:

```make
MOD_ID       := om_japanese_font_pack
MOD_NAME     := Options Menu Japanese Font Pack
MOD_CATEGORY := Options Menu - Addons
MOD_DEPS     := mod/etc/options_menu/fonts/NotoSansJP-CJK.ttf

all: hmod
include vendor/hmod-build/hmod.mk
```

| Variable | Default | |
| --- | --- | --- |
| `MOD_ID` | - | hmod file name and hakchi id |
| `MOD_NAME` | - | `Name:` shown by hakchi |
| `MOD_CATEGORY` | - | `Category:` (the hakchi tab) |
| `MOD_CREATOR` | `DefKorns` | |
| `MOD_DIR` | `mod` | folder that becomes the hmod |
| `MOD_DEPS` | | build outputs to make before packaging; the build fails if one under `MOD_DIR` ends up missing or empty in the hmod |
| `MOD_EXCLUDE` | | file listing paths under `MOD_DIR` to leave out |
| `MOD_VER` | git tag | override, e.g. `make MOD_VER=3.0.0-dev` |

`make hmod-version` prints the version a build would get.

`.github/workflows/build.yml`:

```yaml
name: Build
on:
  push:
    branches: ['**']
    tags: ['v*']
  pull_request:
jobs:
  hmod:
    uses: DefKorns/hmod-build/.github/workflows/hmod.yml@v1.2.0
    with:
      release-name: Options Menu Japanese Font Pack
    secrets: inherit
    permissions:
      contents: write
```

Inputs:

- `make` - one make invocation per line (arguments only), default `hmod`. A mod with two variants lists both, e.g. `-f Makefile.docker` and `-f Makefile.docker FIX_LIBSTDCXX=1`.
- `docker: true` - run make inside the [classicmini-cross-toolchain](https://github.com/DefKorns/classicmini-cross-toolchain) image pinned in `toolchain-image.sh`, pulled from GHCR.

Release notes: write `release-notes/<tag>.md` (e.g. `release-notes/v2.0.0.md`) before tagging and the release uses it as its body, followed by a `**Full Changelog**` compare link to the previous tag. Without that file the release gets GitHub's generated notes.

Keep the `uses:` tag and the submodule on the same release.

The `HUB_DISPATCH_TOKEN` secret (a fine-grained token with *Contents: write* on hakchi-repo) makes the release rebuild the hub straight away; without it the hub catches up on its daily build.

## Compiling Lua

`luajit-bc.sh <source.lua> <output>` compiles a Lua file to the LuaJIT 2.0 bytecode the minis load. The 2.1 that distros ship writes another bytecode version, so it builds LuaJIT 2.0 at a fixed commit into `out/luajit` (needs `git`, `gcc` and `make`) and compiles with that. To build several files, list `<source.lua>:<output>` pairs in `LUAJIT_FILES` and `include vendor/hmod-build/luajit.mk` before `hmod.mk`: every output is built, added to `MOD_DEPS` and covered by `make compile`.

## Building locally

`docker-make.sh` runs make in the pinned toolchain image (`toolchain-image.sh` prints it, pulling it when missing), so a mod's `build.sh` is:

```sh
#!/usr/bin/env bash
set -euo pipefail
[ -f vendor/hmod-build/docker-make.sh ] || git submodule update --init vendor/hmod-build
sh vendor/hmod-build/docker-make.sh "$@"
```

It mounts the outermost git work tree, so a mod checked out as a submodule of another repo still gets its version from `git describe`. It also deletes `*.o` files under `vendor/` afterwards.

To try an unreleased toolchain, build it from a [classicmini-cross-toolchain](https://github.com/DefKorns/classicmini-cross-toolchain) checkout and point `TOOLCHAIN_IMAGE` at it:

```sh
docker build -f Dockerfile.jessie-armhf -t classicmini-cross-toolchain:local .
TOOLCHAIN_IMAGE=classicmini-cross-toolchain:local ./build.sh
```

## Contributing

[pre-commit](https://pre-commit.com/) checks the files you stage before each commit. Set it up once per clone with `pip install pre-commit` and `pre-commit install`; `pre-commit run --all-files` checks everything.
