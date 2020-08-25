#!/usr/bin/python3

import requests
import time

# List of sensor IDs (collected from map)
# around my location in Saratoga, CA
SENSORS=[38547,60735,21449,20609,4299,18299]

# LARPA coef. https://www.lrapa.org/DocumentCenter/View/4147/PurpleAir-Correction-Summary
LC=2.21900

# Rate limit - do not request more than once in 10 minutes
RL=60*10
TSFILE="/tmp/.purple-avg.txt"

def main():

    ts = time.time()

    try:
        with open(TSFILE, "r") as f:
            xts = float(f.readline().strip())
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
        v = float(j['results'][0]['PM2_5Value'])*LC
        t =t+v
        n = n+1

    a = t/n
    
    # update timestamp
    with open(TSFILE, "w") as f:
        f.write(str(ts))
        f.write("\n")
        f.write(str(a))
        f.write("\n")
        
    print("%.0f" % a)

main()
    
