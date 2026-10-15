#!/bin/sh
# Runs make in the toolchain image from the current directory. The outermost
# git work tree is mounted, so a submodule's gitdir resolves for git describe.
set -eu
export MSYS_NO_PATHCONV=1

script_dir=$(cd "$(dirname "$0")" && pwd)
image=$(sh "$script_dir/toolchain-image.sh")

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
while super=$(git -C "$root" rev-parse --show-superproject-working-tree 2>/dev/null) && [ -n "$super" ]; do
  root=$super
done
root=$(cd "$root" && pwd)
host_root=$(cd "$root" && { pwd -W 2>/dev/null || pwd; })
rel=${PWD#"$root"}

# a root container would leave root-owned files behind on Linux/WSL
user_opts=
[ "$(uname -s)" = Linux ] && user_opts="--user $(id -u):$(id -g) -e HOME=/tmp"

status=0
# shellcheck disable=SC2086
docker run --rm $user_opts -v "$host_root:/ws" -w "/ws$rel" "$image" \
  sh -c 'git config --global --add safe.directory "*" 2>/dev/null; exec make CROSS_PREFIX=arm-linux-gnueabihf- "$@"' \
  make "$@" || status=$?

# framework objects would leave a vendor submodule dirty
[ ! -d vendor ] || find vendor -name '*.o' -type f -delete
exit $status
