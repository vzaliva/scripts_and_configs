#!/bin/bash
# Print the absolute path of each given file (like realpath),
# abbreviating the user's home directory as ~.
# With no arguments, print the current directory.

# We want GNU `realpath -m' (path components need not exist).  macOS ships a
# BSD realpath without -m, so fall back to Homebrew coreutils' grealpath, then
# to python3 (os.path.realpath resolves like `realpath -m').  Homebrew's bin
# is appended because non-login shells on macOS don't have it on PATH.
PATH=$PATH:/opt/homebrew/bin:/usr/local/bin
if realpath -m -- / >/dev/null 2>&1; then
    rp=(realpath -m --)
elif command -v grealpath >/dev/null 2>&1; then
    rp=(grealpath -m --)
elif command -v python3 >/dev/null 2>&1; then
    rp=(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))')
else
    echo "${0##*/}: need GNU realpath, grealpath or python3" >&2
    exit 1
fi

[ $# -eq 0 ] && set -- .

rc=0
home=$("${rp[@]}" "$HOME")

for f in "$@"; do
    p=$("${rp[@]}" "$f") || { rc=1; continue; }
    case "$p" in
        "$home")   echo "~" ;;
        "$home"/*) echo "~/${p#"$home"/}" ;;
        *)         echo "$p" ;;
    esac
done

exit $rc
