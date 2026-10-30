# Changelog

## v1.7.1

- Run on `ubuntu-24.04` instead of `ubuntu-latest`, which moves to Ubuntu 26
- Try the release step once more after 30 seconds when the GitHub API drops the connection

## v1.7.0

- `hmod-check.sh` also checks hakchi's install rules: preinit names, final newline, `exit`, top-level `return`, rootfs prefix, capitalised system folders, nested `.hmod`, blacklisted `MOD_ID`; warns on loose root files, non-overlay folders, unknown UI folders and an `install` without `return`

## v1.6.0

- Add `luajit-bc.sh` and `luajit.mk`, which compile Lua files to the LuaJIT 2.0 bytecode the minis load

## v1.5.0

- Use hand-written release notes when present

## v1.4.0

- Make the `.hmod` reproducible (fixed owner, mode, mtime and gzip header)

## v1.3.0

- Pin the toolchain image to v1.2.0 (Options Menu UI font)

## v1.2.0

- Pin the toolchain image to v1.1.0 (curl on mbedTLS)

## v1.1.0

- Add `docker-make.sh`, which mounts the outermost work tree so submodules get their version

## v1.0.0

- Shared versioning, packaging and release workflow for hmods
- Fail the build when a `MOD_DEPS` output is missing or empty in the hmod
- Fail the build on shell syntax errors, CRLF, non-ARM binaries and build leftovers
- List the changes since the previous tag in pre-release readmes
- Pull the toolchain image from GHCR, build it only when unpublished, and pin it by tag
