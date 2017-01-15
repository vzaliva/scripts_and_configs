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
            return f.read().split(',')
    except:
        return ('0','0')

def write_last(v0,v1):
    with open(LAST, 'w') as f:
        return f.write(str.join(",",(v0,v1)))

def get(command):
    return subprocess.check_output(command).decode("utf-8")

c = get(["gsettings", "get", K[0], K[1]]).strip().split()[-1]
(l,c0) = read_last() # read previous transition l->c0
if c0 != c:
    l = c0 # switch via menu detected
subprocess.Popen(["gsettings", "set", K[0], K[1], l])
write_last(c,l) # write current transition c->l

