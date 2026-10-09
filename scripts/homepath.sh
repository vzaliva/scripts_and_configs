#!/bin/bash
# Print the absolute path of each given file (like realpath),
# abbreviating the user's home directory as ~.

if [ $# -eq 0 ]; then
    echo "usage: ${0##*/} FILE..." >&2
    exit 1
fi

rc=0
home=$(realpath -m -- "$HOME")

for f in "$@"; do
    p=$(realpath -m -- "$f") || { rc=1; continue; }
    case "$p" in
        "$home")   echo "~" ;;
        "$home"/*) echo "~/${p#"$home"/}" ;;
        *)         echo "$p" ;;
    esac
done

exit $rc
