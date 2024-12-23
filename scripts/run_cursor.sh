#!/bin/bash
latest=$(ls /home/lord/Applications/cursor-*.AppImage | sort | tail -n 1)
"$latest" "$@"

