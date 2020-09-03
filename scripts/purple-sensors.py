#!/usr/bin/python3

import requests
import time
import os
import json
import math
from math import radians, sin, cos

# Coordinates of place near which we want to find sensors
# To find coordinates of a place:
#    1. On your computer, open Google Maps. If you're using Maps in Lite mode,
#       you'll see a lightning bolt at the bottom and you won't be able to get 
#       the coordinates of a place.
#    2. Right-click the place or area on the map.
#    3. Select What's here?
#    4. At the bottom, you'll see a card with the coordinates.

mylat = radians(37.256886)
mylon = radians(-122.039156)

# max number of sensors to return
MAX_SENSORS = 30
# Max ditance in Km from my location
RADIUS = 5

# Sensors fetch rate limit - do not request more than once in 10 minutes
SRL=60*10
# Cache file to store cached sensor list
DATAFILE=os.path.expanduser("~/.purple-sensors.cache")
# Output file to write down list of sensors
OUTFILE=os.path.expanduser("~/.purple-sensors.list")

def distance(lat1, lon1, lat2, lon2):
    R = 6373.0 # Earth radius
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2 #Haversine formula
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def main():

    ts = time.time()

    try:
        xts = os.path.getmtime(DATAFILE)
        with open(DATAFILE, "r") as f:
            data = json.load(f)            
    except:
        xts = 0.0

    if ts-xts > SRL:
        # need to fetch new data
        u = "https://www.purpleair.com/json"
        r = requests.get(u)
        data = r.json()
        with open(DATAFILE, 'w') as f:
            json.dump(data, f)

    sensors = []
    for i in data['results']:
        #print('-------------------------------------------')
        #print(i)
        lat = i.get('Lat')
        lon = i.get('Lon')
        if not lat is None and not lon is None:
            d = distance(mylat, mylon, radians(lat), radians(lon))
            if (i.get('DEVICE_LOCATIONTYPE','') == 'outside') and (i['Hidden'] == 'false') and d <RADIUS:
                sensors.append({'id':i['ID'],'distance':d})
                if len(sensors) == MAX_SENSORS:
                    break

    with open(OUTFILE, 'w') as f:
        json.dump(sensors, f)

main()
    
