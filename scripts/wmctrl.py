#!/usr/bin/env python3

# Assumptions:
#  1. Compiz
#  2. same workarea accross desktops

# Single

# $ wmctrl -d 
#0  * DG: 3840x2160  VP: 0    ,0     WA: 49,18 1871x1062  N/A
#0  * DG: 3840x2160  VP: 1920 ,0     WA: 49,18 1871x1062  N/A
#0  * DG: 3840x2160  VP: 0    ,1080  WA: 49,18 1871x1062  N/A
#0  * DG: 3840x2160  VP: 1920 ,1080  WA: 49,18 1871x1062  N/A

# $ dconf read /org/compiz/profiles/unity/plugins/core/outputs
#['1920x1080+0+0']

# Double

# $ wmctrl -d 
#0  * DG: 11520x4320  VP: 0    ,0     WA: 49,15 5711x2145  N/A
#0  * DG: 11520x4320  VP: 5760 ,0     WA: 49,15 5711x2145  N/A
#0  * DG: 11520x4320  VP: 0    ,2160  WA: 49,15 5711x2145  N/A
#0  * DG: 11520x4320  VP: 5760 ,2160  WA: 49,15 5711x2145  N/A

# $ dconf read /org/compiz/profiles/unity/plugins/core/outputs
#['1920x1080+0+0', '3840x2160+1920+0']


import subprocess
import os, sys, time, re

def intlist(l):
    return list(map(int, l))

def parse_desktop(s):
    f = s.split()
    n = int (f[0])
    wh = intlist(f[8].split('x')) # WA
    xy = intlist(f[7].split(',')) # WA
    vxy = intlist(f[5].split(',')) # VP
    dwh = intlist(f[3].split('x')) # DG
    res = {
        # Is display current?
        'is_current': f[1]=='*',
        # Display geometry:
        'display_w' : dwh[0], 
        'display_h' : dwh[1],
        # Viewport position:
        'viewport_x': vxy[0], 
        'viewport_y': vxy[1],
        # Viewing Area:
        'area_x': xy[0], 
        'area_y': xy[1],
        'area_w': wh[0],
        'area_h': wh[1]
        }
    return (n,res)

def dconf_read(k):
    return subprocess.check_output(["dconf", "read", k]).decode("utf-8").strip()

def get_workspaces():
    # should be using Gio
    w = [int (dconf_read(k)) for k in
        ["/org/compiz/profiles/unity/plugins/core/hsize",
        "/org/compiz/profiles/unity/plugins/core/hsize"]]
    return {
        'hsize': w[0],
        'vsize': w[1]
        }

def get_desktops():
    return dict([parse_desktop(l) for l in subprocess.check_output(["wmctrl", "-d"]).decode("utf-8").splitlines()])


def parse_output(s):
    l = intlist(re.split(r'[x\+]',s))
    return {
        'w': l[0],
        'h': l[1],
        'x': l[2],
        'y': l[3]
        }

def get_outputs():
    s = dconf_read("/org/compiz/profiles/unity/plugins/core/outputs")
    return [parse_output(o.strip(' []\'')) for o in s.split(",")]
        
def get_wm_info():
    res = {
        "desktops" : get_desktops(),
        "workspaces": get_workspaces(),
        "outputs": get_outputs()
        }
    return res




import pprint
ctx = get_wm_info()
pprint.pprint (ctx)
 
#subprocess.Popen(["wmctrl","-r", "emacs@nemo", "-e", "0,1969,18,1871,1062"])
