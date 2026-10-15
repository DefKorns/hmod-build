# hmod-build

Shared versioning, packaging and release workflow for my hakchi hmods, so every mod is built the same way.

## What every mod gets

- **Version from the git tag only.** Tag `v3.0.0-alpha4` builds version `3.0.0-alpha4`; an untagged build is `3.0.0-alpha4-3-gabc1234` (`git describe`). No `VERSION` file.
- **Fixed file name:** `out/<MOD_ID>.hmod`, no version in it. Hakchi uses the file name as the mod's id, so a versioned name would install every update as a separate mod.
- **The same readme header:** Name, Creator, Category, Version, Built on, Git commit. The body is the mod's own `mod/readme.md`, without its leading `# title` line.
- **A changelog in pre-release readmes:** when the version has a `-` (`3.0.0-alpha4`, or an untagged build), the readme gets a `## Changes since <previous tag>` list of the commit subjects since that tag, so testers see what changed. Stable releases don't get it.
- **A smoke test of the packaged files** (`hmod-check.sh`, run before the hmod is written): the build fails on a shell syntax error in `install`, `uninstall` or any `sh`/`bash`/`ash` script, CRLF line endings in a text file, an ELF binary that isn't 32-bit ARM, or a `*.o`, `.DS_Store`, `Thumbs.db` or `desktop.ini` leftover.
- **A release per `v*` tag** (pre-release when the tag has a `-`), and a rebuild of the [hakchi-repo](https://github.com/DefKorns/hakchi-repo) hub right after.

## Use it in a mod

Add it as a submodule:

```sh
git submodule add https://github.com/DefKorns/hmod-build.git hmod-build
```

`Makefile`:

```make
MOD_ID       := om_japanese_font_pack
MOD_NAME     := Options Menu Japanese Font Pack
MOD_CATEGORY := Options Menu - Addons
MOD_DEPS     := mod/etc/options_menu/fonts/NotoSansJP-CJK.ttf

all: hmod
include hmod-build/hmod.mk
```

| Variable | Default | |
|---|---|---|
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
    uses: DefKorns/hmod-build/.github/workflows/hmod.yml@master
    with:
      release-name: Options Menu Japanese Font Pack
    secrets: inherit
    permissions:
      contents: write
```

Inputs:

- `make` - one make invocation per line (arguments only), default `hmod`. A mod with two variants lists both, e.g. `-f Makefile.docker` and `-f Makefile.docker FIX_LIBSTDCXX=1`.
- `docker: true` - run make inside the [classicmini-cross-toolchain](https://github.com/DefKorns/classicmini-cross-toolchain) image (needs the `toolchain/` submodule).

The `HUB_DISPATCH_TOKEN` secret (a fine-grained token with *Contents: write* on hakchi-repo) makes the release rebuild the hub straight away; without it the hub catches up on its daily build.
