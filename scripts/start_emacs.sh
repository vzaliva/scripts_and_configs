#!/bin/sh
wmctrl -c "emacs@nemo"
nohup emacs &
sleep 2
wmctrl -r "emacs@nemo" -e 0,1969,18,1871,1062

