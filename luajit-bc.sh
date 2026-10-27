#!/bin/sh
# Compiles a Lua file to LuaJIT 2.0 bytecode: luajit-bc.sh <source.lua> <output>
# The minis load bytecode version 1, which the 2.1 that distros ship does not write,
# so LuaJIT 2.0 is built at a fixed commit under $LUAJIT_DIR (default out/luajit).
set -eu
src=${1:?usage: luajit-bc.sh <source.lua> <output>}
out=${2:?usage: luajit-bc.sh <source.lua> <output>}
ref=2410b57fd466298e6a64a68986a6b696c23656ac
dir=${LUAJIT_DIR:-out/luajit}

if [ ! -x "$dir/src/luajit" ]; then
  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" fetch -q --depth 1 https://github.com/LuaJIT/LuaJIT "$ref"
  git -C "$dir" checkout -q FETCH_HEAD
  [ "$(git -C "$dir" rev-parse HEAD)" = "$ref" ] || {
    echo "luajit-bc.sh: LuaJIT is not at $ref" >&2
    exit 1
  }
  make -C "$dir" -s
fi

mkdir -p "$(dirname "$out")"
LUA_PATH="$(cd "$dir/src" && pwd)/?.lua;;" "$dir/src/luajit" -bs "$src" "$out"
