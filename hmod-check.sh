#!/bin/sh
# Smoke test for an hmod tree: hmod-check.sh <dir> [mod id]
dir=${1:?usage: hmod-check.sh <dir> [mod id]}
mod_id=$2
cd "$dir" || exit 1

if command -v bash >/dev/null 2>&1; then parse="bash -n"; else parse="sh -n"; fi
cr=$(printf '\r')
fail=0

err() {
  echo "hmod-check: $*" >&2
  fail=1
}

warn() {
  echo "hmod-check: warning: $*" >&2
}

stripComments() {
  sed -E 's/(^|[[:space:]])#.*$//' "$1"
}

hasExit() {
  stripComments "$1" | grep -Eq '(^|[;&|({]|(^|[[:space:]])(then|do|else))[[:space:]]*exit([[:space:];]|$)'
}

hasTopLevelReturn() {
  stripComments "$1" | awk '
    { s = $0; gsub(/\$\{[^}]*\}/, "", s)
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "{") depth++
        else if (c == "}") { if (depth > 0) depth-- }
        else if (c == "r" && depth == 0 && substr(s, i, 6) == "return") {
          after = substr(s, i + 6, 1)
          if ((after == "" || after ~ /^[[:blank:];]$/) && substr(s, 1, i - 1) ~ /(^|[;&|({]|[[:blank:]](then|do|else)|^(then|do|else))[[:blank:]]*$/) bad = 1
        }
      }
    }
    END { exit !bad }'
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

  top=${f%%/*}
  if [ "$top" = "$f" ]; then
    case $f in
      install | uninstall | transfer | [Rr]eadme* | *.txt | *.md) ;;
      *) warn "$f: loose file at the package root, hakchi copies it to /" ;;
    esac
  else
    case $top in
      bin | sbin | etc | lib | usr | root) ;;
      var | tmp | media | mnt | dev | proc | sys | newroot) warn "$f: /$top is mounted over at boot, so this is hidden" ;;
      rootfs | hakchi) err "$f: path already includes the hakchi rootfs" ;;
      *)
        lower=$(printf %s "$top" | tr '[:upper:]' '[:lower:]')
        case $lower in
          bin | sbin | etc | lib | usr | root | var | tmp | media | mnt | dev | proc | sys) err "$f: system folders are lowercase on the console" ;;
          *) warn "$f: /$top is not an overlay root (bin, sbin, etc, lib, usr, root)" ;;
        esac
        ;;
    esac
  fi
  case $f in
    var/lib/hakchi/rootfs/*) err "$f: path already includes the hakchi rootfs" ;;
    *.hmod | *.hmod/*) err "$f: hakchi skips nested .hmod files" ;;
    usr/share/ui/*/*)
      ui=${f#usr/share/ui/}
      case ${ui%%/*} in
        snes-usa | snes-eur | shvc | hvc) ;;
        *) warn "$f: no console reads usr/share/ui/${ui%%/*}" ;;
      esac
      ;;
    etc/preinit.d/*)
      name=${f#etc/preinit.d/}
      case $name in
        */*) err "$f: hakchi only runs scripts directly in etc/preinit.d" ;;
        [bp]????_*)
          grep -Iq '' "$f" 2>/dev/null || err "$f: binary file in etc/preinit.d"
          [ -z "$(tail -c 1 "$f")" ] || err "$f: no final newline, hakchi joins preinit scripts so it merges with the next one"
          hasExit "$f" && err "$f: exit aborts every preinit script after it"
          hasTopLevelReturn "$f" && err "$f: return outside a function ends the joined preinit file and skips every script after it"
          ;;
        *) err "$f: never runs, hakchi only sources b????_* and p????_* here" ;;
      esac
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
  case $f in
    install | uninstall | transfer)
      hasExit "$f" && err "$f: exit ends the whole hakchi install, use return"
      ;;
  esac
  if [ "$f" = install ]; then
    last=$(stripComments "$f" | sed '/^[[:space:]]*$/d' | tail -n 1)
    case $last in
      *return*) ;;
      *) warn "install: does not end with return, a failing last command makes hakchi skip copying the files" ;;
    esac
  fi
  [ "$script" = 1 ] || continue
  out=$($parse "$f" 2>&1) || err "$f: shell syntax error
$out"
done < "${TMPDIR:-/tmp}/hmod-check.$$"
rm -f "${TMPDIR:-/tmp}/hmod-check.$$"

case $mod_id in
  clovershell | extra_space | fontfix | multiboot_fixes | nesc_hybrid_system | password | shonen_fix | tiny7zx-dynamic | zram-3.4.113.23-madmonkey)
    err "$mod_id: hakchi refuses to install a package with this name"
    ;;
esac

exit "$fail"
