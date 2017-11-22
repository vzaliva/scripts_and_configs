#!/usr/bin/env python3

# Assumptions:
#  1. compiz
#  2. same workarea accross desktops

#0 #0  * DG: 3840x2160  VP: 0    ,0     WA: 49,18 1871x1062  N/A
#1 #0  * DG: 3840x2160  VP: 1920 ,0     WA: 49,18 1871x1062  N/A
#2 #0  * DG: 3840x2160  VP: 0    ,1080  WA: 49,18 1871x1062  N/A
#3 #0  * DG: 3840x2160  VP: 1920 ,1080  WA: 49,18 1871x1062  N/A

import subprocess
import os, sys, time

def intlist(l):
    return list(map(int, l))

def parse_desktop(s):
    f = s.split()
    n = int (f[0])
    res = {
        'is_current': f[1]=='*',
        'geometry' : intlist(f[3].split('x')),
        'viewport': intlist(f[5].split(',')),
        'x_y': intlist(f[7].split(',')),
        'w_h': intlist(f[8].split('x'))
        }
    return (n,res)

def dconf_read(k):
    return subprocess.check_output(["dconf", "read", k]).decode("utf-8").strip()

def get_workspaces():
    # should be using Gio
    return [int (dconf_read(k)) for k in
        ["/org/compiz/profiles/unity/plugins/core/hsize",
        "/org/compiz/profiles/unity/plugins/core/hsize"]]

def get_desktops():
    return dict([parse_desktop(l) for l in subprocess.check_output(["wmctrl", "-d"]).decode("utf-8").splitlines()])

def get_wm_info():
    res = {
        "desktops" : get_desktops(),
        "workspaces": get_workspaces()
        }
    return res

ctx = get_wm_info()
print (ctx)
 
#subprocess.Popen(["wmctrl","-r", "emacs@nemo", "-e", "0,1969,18,1871,1062"])
