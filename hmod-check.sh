#!/bin/sh
# Smoke test for an hmod tree: hmod-check.sh <dir>
dir=${1:?usage: hmod-check.sh <dir>}
cd "$dir" || exit 1

if command -v bash >/dev/null 2>&1; then parse="bash -n"; else parse="sh -n"; fi
cr=$(printf '\r')
fail=0

err() {
  echo "hmod-check: $*" >&2
  fail=1
}

byte() {
  od -An -tu1 -j"$2" -N1 "$1" | tr -d ' '
}

find . -type f | sed 's#^\./##' | sort > "${TMPDIR:-/tmp}/hmod-check.$$"
while IFS= read -r f; do
  case ${f##*/} in
    *.o | .DS_Store | Thumbs.db | desktop.ini)
      err "$f: build or OS leftover"
      continue
      ;;
  esac

  if [ "$(head -c 4 "$f" | od -An -c | tr -d ' ')" = '177ELF' ]; then
    [ "$(byte "$f" 4)" = 1 ] && [ "$(byte "$f" 18)" = 40 ] && [ "$(byte "$f" 19)" = 0 ] ||
      err "$f: not a 32-bit ARM binary"
    continue
  fi

  grep -Iq '' "$f" 2>/dev/null || continue
  grep -Uq "$cr" "$f" && err "$f: CRLF line endings"

  case $f in
    install | uninstall) script=1 ;;
    *) head -n 1 "$f" | grep -Eq '^#! */(usr/)?bin/(env +)?(ba|a)?sh' && script=1 || script=0 ;;
  esac
  [ "$script" = 1 ] || continue
  out=$($parse "$f" 2>&1) || err "$f: shell syntax error
$out"
done < "${TMPDIR:-/tmp}/hmod-check.$$"
rm -f "${TMPDIR:-/tmp}/hmod-check.$$"

exit "$fail"
