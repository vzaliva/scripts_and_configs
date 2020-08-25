#!/usr/bin/python3

import requests
import time
import os

# List of sensor IDs (collected from map)
# around my location in Saratoga, CA
SENSORS=[38547,60735,21449,20609,4299,18299]

# LRAPA correction https://www.lrapa.org/DocumentCenter/View/4147/PurpleAir-Correction-Summary
def LRAPA(x):
    return 0.5*x-0.66

# Rate limit - do not request more than once in 10 minutes
RL=60*10
TSFILE=os.path.expanduser("~/.purple-avg.cache")

def main():

    ts = time.time()

    try:
        xts = os.path.getmtime(TSFILE)
        with open(TSFILE, "r") as f:
            xv = float(f.readline().strip())
    except:
        xts = 0.0

    if ts-xts < RL:
        print("%.0f" % xv)
        exit(0)
                
    t = 0.0
    n = 0
    for i in SENSORS:
        u = "https://www.purpleair.com/json?show=%d"%i
        r = requests.get(u)
        j = r.json()
        raw = float(j['results'][0]['PM2_5Value'])
        # sanity check, some sensors return 0.0
        if raw>1.0:
            v = LRAPA(raw)
            t = t+v
            n = n+1

    a = round(t/n)
    
    # update timestamp
    with open(TSFILE, "w") as f:
        f.write(str(a))
        f.write("\n")
        
    print("%.0f" % a)

main()
    
