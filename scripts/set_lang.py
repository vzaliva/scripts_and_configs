#!/usr/bin/env python3

import subprocess
import sys

args = sys.argv[1:]
k = ["org.gnome.desktop.input-sources", "current"]

def get(command):
    return subprocess.check_output(command).decode("utf-8")
    
currlang = get(["gsettings", "get", k[0], k[1]]).strip().split()[-1]
newlang = args[1] if currlang == args[0] else args[0]
subprocess.Popen(["gsettings", "set", k[0], k[1], newlang])

