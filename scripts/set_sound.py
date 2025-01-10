#!/usr/bin/env python3

# automatically guess and set sound outputs
# Requires: https://github.com/mk-fg/python-pulse-control
# Install `python3-pulsectl` and `python3-icecream` apt package.


import pulsectl
from icecream import ic

# preferred input sinks (in this order)
PREF_SINKS = ["WH-1000XM4 (grey, over-ear)", "WF-1000XM5 (earbuds)", "WH-CH520 (white, over-ear)","Raptor Lake-P/U/H cAVS Speaker + Headphones", "Jabra EVOLVE 30 II Analog Stereo"]

def find_sink(s,lst):
    return(next(filter((lambda x: x.description==s), lst), None))

with pulsectl.Pulse('volume-increaser') as pulse:
    #ic(pulse.sink_list())
    for d in PREF_SINKS:
        s = find_sink(d, pulse.sink_list())
        if s is not None:
            print("Sound sink set to: %s" % s.description)
            pulse.default_set(s)
            #ic (pulse.sink_input_list())
            #ic (pulse.card_list())
            #ic (pulse.module_list())
            #ic (pulse.client_list())
            # port_set(_,_)
            #ic(pulse.source_list())
            break
