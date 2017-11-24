#!/bin/sh

wmctrl -c "emacs@nemo"
nohup emacs &
sleep 1
wmctrl -r emacs@nemo -e `wmcalc -m0 -c1 -r0`


