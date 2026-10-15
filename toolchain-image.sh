#!/bin/sh
# Prints a local image for the toolchain submodule's pinned commit:
# toolchain-image.sh [toolchain-dir]
# Pulled from GHCR when published, otherwise built from the submodule;
# local changes in the submodule always build.
set -eu
dir=${1:-toolchain}
repo=ghcr.io/defkorns/classicmini-cross-toolchain

if [ -n "$(git -C "$dir" status --porcelain)" ]; then
  image=classicmini-cross-toolchain:local
  docker build -q -f "$dir/Dockerfile.jessie-armhf" -t "$image" "$dir" >&2
  echo "$image"
  exit 0
fi

image=$repo:sha-$(git -C "$dir" rev-parse --short=7 HEAD)
if ! docker image inspect "$image" >/dev/null 2>&1; then
  if ! docker pull -q "$image" >&2 2>/dev/null; then
    echo "toolchain-image: $image not published, building it" >&2
    docker build -q -f "$dir/Dockerfile.jessie-armhf" -t "$image" "$dir" >&2
  fi
fi
echo "$image"
