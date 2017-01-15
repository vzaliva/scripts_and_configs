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
from gi.repository import Gio

LAST = '/dev/shm/last-input.txt'
SCHEMA = 'org.gnome.desktop.input-sources'
KEY = 'current'

def read_last():
    try:
        with open(LAST, 'r') as f:
            return tuple(map(int, f.read().split(',')))
    except:
        return (0,0)

def write_last(v0,v1):
    with open(LAST, 'w') as f:
        return f.write(str.join(",",(str(v0),str(v1))))

g = Gio.Settings.new(SCHEMA)

c = g.get_uint(KEY)
(l,c0) = read_last() # read previous transition l->c0
print(c,l,c0)
if c0 != c:
    l = c0 # switch via menu detected
g.set_uint(KEY,l)
write_last(c,l) # write current transition c->l

