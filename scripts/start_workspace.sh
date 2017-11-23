#!/bin/sh

killall chrome
sleep 2
nohup google-chrome --profile-directory="Profile 1" &
sleep 1
nohup google-chrome --profile-directory=Default&
sleep 1

# Hacky! Uses last 2 windows open
c=`wmctrl -lp | cut -d' ' -f1| tail -2`
c1=`echo $c | cut -d' ' -f1`
c2=`echo $c | cut -d' ' -f2`

wmctrl -ir $c1 -e `wmcalc -m0 -c0 -r1`
wmctrl -ir $c2 -e `wmcalc -m0 -c1 -r1`

wmctrl -c "emacs@nemo"
nohup emacs &
sleep 1
wmctrl -r emacs@nemo -e `wmcalc -m0 -c1 -r0`


