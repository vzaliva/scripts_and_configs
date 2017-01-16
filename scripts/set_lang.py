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
# read previous transition l->c0
(l,c0) = read_last() 

if c0 != c:
    # switch via menu detected
    l = c0

if l == c:
    # we are stuck!
    if l != 0:
        # if we stuck at non-0, switching to source 0
        # which is assumed to be always present is an alternative
        l = 0
    else:
        # if we stuck at source #0 try to pick up an alternative
        # see if we have more than one, and switch to #1
        if len(g.get_value('sources')) > 1:
            l = 1
            
g.set_uint(KEY,l)
# write current transition c->l
write_last(c,l) 

