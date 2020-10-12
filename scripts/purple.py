#!/usr/bin/python3

import requests
import time
import os
import json
import math
from math import radians, sin, cos
import click

# Filter sensor data by this interval (sanity check)
PM_25_UPPER_LIMIT = 500 # inclusive
PM_25_LOWER_LIMIT = 1 # exclusive

# Coordinates of place near which we want to find sensors
# To find coordinates of a place:
#    1. On your computer, open Google Maps. If you're using Maps in Lite mode,
#       you'll see a lightning bolt at the bottom and you won't be able to get 
#       the coordinates of a place.
#    2. Right-click the place or area on the map.
#    3. Select What's here?
#    4. At the bottom, you'll see a card with the coordinates.

def distance(lat1, lon1, lat2, lon2):
    R = 6373.0 # Earth radius
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2 #Haversine formula
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# LRAPA correction https://www.lrapa.org/DocumentCenter/View/4147/PurpleAir-Correction-Summary
def LRAPA(x):
    return 0.5*x-0.66

# EPA correction https://cfpub.epa.gov/si/si_public_file_download.cfm?p_download_id=540979&Lab=CEMM
# PM2.5 corrected= 0.52*[PA_cf1(avgAB)] - 0.085*RH +5.71
# x - raw PM2.5 value
# h - humidity
def EPA(x, h):
    return max(0.534 * x - 0.0844 * h + 5.604, 0)

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

def get_update_server_list(verbose, sensors_list_ttl, sensors_list_cache_file):
    
    ts = time.time()
    try:
        xts = os.path.getmtime(sensors_list_cache_file)
        with open(sensors_list_cache_file, "r") as f:
            data = json.load(f)
            if verbose:
                print("Server list cache loaded")
    except:
        print("Error reading server list")
        xts = 0.0

    if ts-xts > sensors_list_ttl:
        if verbose:
            print("Fetching server list")
        u = "https://www.purpleair.com/json"
        r = requests.get(u)
        data = r.json()
        with open(sensors_list_cache_file, 'w') as f:
            if verbose:
                print("Saving server list")
            json.dump(data, f)
    return data

@click.command()
@click.option('--verbose', is_flag=True)
@click.option('--radius', default=5.0, help='Radius in miles')
@click.option('--lat', default=37.256886, help='Lattitude in radians')
@click.option('--lon', default=-122.039156, help='Lattitude in radians')
@click.option('--max-sensors', default=30, help='max number of sensors to query')
@click.option('--sensors-list-ttl', default=1800, help='How often to update sensor list cache (in seconds)')
@click.option('--sensors-list-cache-file', default=os.path.expanduser("~/.purple-all-sensors.list"), help='sensor list cache file location')
@click.option('--results-ttl', default=600, help='How often to update sensor reading (in seconds))')
@click.option('--results-cache-file', default=os.path.expanduser("~/.purple-avg.cache"), help='results cache file location')
@click.option('--max-age', default=10, help='filer out sensors not reporting data given number of minutes')

def purple(verbose,
           radius, lat, lon,
           max_sensors, sensors_list_ttl, sensors_list_cache_file,
           results_ttl, results_cache_file,
           max_age
           ):
    mylat = radians(37.256886)
    mylon = radians(-122.039156)
    
    if verbose:
        print("Coordinates: %f,%f" % (lat,lon))

    data = get_update_server_list(verbose, sensors_list_ttl, sensors_list_cache_file)
    
    if verbose:
        print("Loaded %d sensors" % len(data['results']))

    # filter sensors    
    sensors = []
    for i in data['results']:
        lat = i.get('Lat')
        lon = i.get('Lon')
        if not lat is None and not lon is None:
            d = distance(mylat, mylon, radians(lat), radians(lon))
            if (i.get('DEVICE_LOCATIONTYPE','') == 'outside') and (i['Hidden'] == 'false') and d<radius:
                sensors.append({'id':i['ID'],'distance':d})
                if len(sensors) == max_sensors:
                    break
    if verbose:
        print("Found %d suitable sensors" % len(sensors))

    ts = time.time()

    #TODO: write location to cache file and invalidate it if it changes
    try:
        xts = os.path.getmtime(results_cache_file)
        with open(results_cache_file, "r") as f:
            xv = float(f.readline().strip())
    except:
        print("Error reading cached value")
        xts = 0.0

    if ts-xts < results_ttl:
        if verbose:
            print("Returning cached value")
        print("%.0f" % xv)
        exit(0)

    t  = 0.0
    dt = 0.0
    for i in sensors:
        u = "https://www.purpleair.com/json?show=%d"% i['id']
        r = requests.get(u)
        j = r.json()

        # Channels a, b
        a = j['results'][0]
        b = j['results'][1]
        
        raw0 = float(a['pm2_5_cf_1'])
        raw1 = float(b['pm2_5_cf_1'])
        # humidity only stored for channel a
        humidity = float(a['humidity'])
        
        age0 = j['results'][0]['AGE']
        age1 = j['results'][1]['AGE']

        # oh, Python....
        if age0 > max_age:
            if age1 > max_age:
                if verbose:
                    print("Skipping sensor %d because both channels are stale" % i['id'])
                continue
            else:
                if verbose:
                    print("Skipping stale channel A of sensor %d" % i['id'])
                raw = raw1
        else:
            if age1 > max_age:
                if verbose:
                    print("Skipping stale channel B of sensor %d" % i['id'])
                raw = raw0
            else:
                raw = (raw0+raw1)/2 # averaging channels
        
        d = i['distance']
        
        # sanity check, some sensors return 0.0 (instant)
        # TODO: this is hacky, need to do proper statistical
        # filtering of outliers based on distribution
        if raw>=PM_25_LOWER_LIMIT and raw<PM_25_UPPER_LIMIT and d<radius:
            d = radius-d # proximity weight
            dt = dt + d
            v = EPA(raw, humidity)
            t = t + (v*d)

    a = round(AQI(t/dt))
    
    # update timestamp
    with open(results_cache_file, "w") as f:
        f.write(str(a))
        f.write("\n")
        
    print("%.0f" % a)
            
if __name__ == '__main__':
    purple()

    
