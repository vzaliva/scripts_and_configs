#!/usr/bin/env python3

import subprocess
import os, sys, time

def get_chromes():
    # get the list of pids of chrome
    pids = [p for p in subprocess.check_output(["pgrep", "chrome"]).decode("utf-8").splitlines()]
    # get the list of windows
    windows = [l.split() for l in subprocess.check_output(["wmctrl", "-lp"]).decode("utf-8").splitlines()]
    # filter out the windows of chrome, parse their window-id
    return [w[0] for w in windows if w[2] in pids]

l=[]
while len(l)!=2:
      l = get_chromes()
      print (l)
 
# Re-position Chrome windows
subprocess.Popen(["wmctrl", "-ir", l[0], "-e", "0,0,1098,1863,1041"]) #CMU
subprocess.Popen(["wmctrl", "-ir", l[1], "-e", "0,1969,1098,18531,1062"]) #Vadim

# Re-position Emacs
subprocess.Popen(["wmctrl","-r", "emacs@nemo", "-e", "0,1969,18,1871,1062"])
