#!/bin/sh
# Prints the toolchain image every mod builds with, pulling it when missing.
# TOOLCHAIN_IMAGE overrides it, e.g. a local build of classicmini-cross-toolchain.
set -eu
image=${TOOLCHAIN_IMAGE:-ghcr.io/defkorns/classicmini-cross-toolchain:v1.2.0}

if ! docker image inspect "$image" >/dev/null 2>&1; then
  docker pull -q "$image" >&2
fi
echo "$image"
