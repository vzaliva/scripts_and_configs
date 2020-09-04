#!/usr/bin/python3

import requests
import time
import os
import json

# Max ditance in Km from my location
RADIUS = 5

# List of sensor IDs (collected from map)
# around my location in Saratoga, CA
SENSORS=[{"id": 60735, "distance": 2.257297198870022},
         {"id": 20527, "distance": 1.8239682865311586},
         {"id": 44279, "distance": 4.62075329916058},
         {"id": 56247, "distance": 2.8376153149891783},
         {"id": 35865, "distance": 3.2308737834589127},
         {"id": 60067, "distance": 4.076598582024505},
         {"id": 60069, "distance": 3.2609348136271965},
         {"id": 18299, "distance": 2.550106833233925},
         {"id": 54459, "distance": 4.788853289853395},
         {"id": 54535, "distance": 4.044601652815528},
         {"id": 19627, "distance": 3.848998375631747},
         {"id": 61597, "distance": 2.0742910655994704},
         {"id": 60011, "distance": 4.617712394228733},
         {"id": 19425, "distance": 3.4749061430139965},
         {"id": 20609, "distance": 3.2091593993558054},
         {"id": 44911, "distance": 1.485555668250782},
         {"id": 58961, "distance": 2.076424414263944},
         {"id": 4299, "distance": 2.448843044047881},
         {"id": 21449, "distance": 1.5192171030891888},
         {"id": 38547, "distance": 0.8724871926876482},
         {"id": 61759, "distance": 3.9470412308559744}]

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
        if raw>5.0 and d<RADIUS:
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
    
