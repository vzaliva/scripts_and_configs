#!/usr/bin/env python3
#
# Script to toggle between the two last used language in Gnome
# 
# History:
#
# Original script by Jacob Vlijm
# Saving last language and togging: Vadim Zaliva
#
# See also: http://askubuntu.com/questions/871678/how-can-i-quickly-switch-between-two-out-of-multiple-languages
#

import subprocess
import sys

LAST='/dev/shm/last-input.txt'
K = ["org.gnome.desktop.input-sources", "current"]

def read_last():
    try:
        with open(LAST, 'r') as f:
            return f.read()
    except:
        return '0'

def write_last(v):
    with open(LAST, 'w') as f:
        return f.write(v)


def get(command):
    return subprocess.check_output(command).decode("utf-8")

currlang = get(["gsettings", "get", K[0], K[1]]).strip().split()[-1]
lastlang = read_last()
subprocess.Popen(["gsettings", "set", K[0], K[1], lastlang])
write_last(currlang)

