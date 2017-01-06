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

# Get active chrome windows
#l = get_chromes()
#for x in l:
#    print("Closing window %s" % x)
#    subprocess.Popen(["wmctrl", "-ic", x])

# Start chrome

subprocess.Popen(['google-chrome --profile-directory="Profile 1"'],
                     shell=True, stdin=None, stdout=None, stderr=None, close_fds=True)
time.sleep(1)

subprocess.Popen(['google-chrome --profile-directory=Default'],
                     shell=True, stdin=None, stdout=None, stderr=None, close_fds=True)

l=[]
while len(l)!=2:
      l = get_chromes()
      print (l)
 
# Re-position windows
subprocess.Popen(["wmctrl", "-ir", l[0], "-e", "0,0,1098,1863,1041"]) #CMU
subprocess.Popen(["wmctrl", "-ir", l[1], "-e", "0,1969,1098,18531,1062"]) #Vadim
