#!/usr/bin/python3

import requests
import time
import os
import json

# Max ditance in Km from my location
RADIUS = 5

with open(".purple-sensors.list") as f: 
   SENSORS = json.load(f) 

# LRAPA correction https://www.lrapa.org/DocumentCenter/View/4147/PurpleAir-Correction-Summary
def LRAPA(x):
    return 0.5*x-0.66

# Calculate AQI for PM2.5.
# https://www3.epa.gov/airnow/aqi-technical-assistance-document-sept2018.pdf

breakpoints=[(0.0  , 12.0,  0,   50),
             (12.1 , 35.4,  51,  100),
             (35.5 , 55.4,  101, 150),
             (55.5 , 150.4, 151, 200),
             (150.5, 250.4, 201, 300),
             (250.5, 350.4, 301, 400),
             (350.5, 500.4, 401, 500)]

def AQI(pm25):
    Cp = round(pm25,1)
    for (Blo,Bhi,Ilo,Ihi) in breakpoints:
        if Cp>=Blo and Cp<=Bhi:
            return ((float(Ihi)-float(Ilo))/(Bhi-Blo))*(Cp-Blo)+float(Ilo)
    return 501 #  "Beyond the AQI"

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
                
    t  = 0.0
    dt = 0.0
    for i in SENSORS:
        u = "https://www.purpleair.com/json?show=%d"% i['id']
        r = requests.get(u)
        j = r.json()
        # using 10-min average
        stats = json.loads(j['results'][0]['Stats'])
        raw = float(stats['v1'])
        # sanity check, some sensors return 0.0 (instant)
        # this is hacky, need to do proper statistical
        # filtering of outliers based on distribution
        # TODO: use 'AGE' field to filter stale data
        d = i['distance']
        if raw>1.0 and d<RADIUS:
            d = RADIUS-d # proximity weight
            dt = dt + d
            v = LRAPA(raw)
            t = t + (v*d)

    a = round(AQI(t/dt))
    
    # update timestamp
    with open(TSFILE, "w") as f:
        f.write(str(a))
        f.write("\n")
        
    print("%.0f" % a)

main()
    
