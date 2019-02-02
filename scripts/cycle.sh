#!/bin/bash

#
# A script to cycle through several commands.
# Given a list of commands, each time it is invoked it will
# execute the next one from the list.
#
# Example:
#
# $./cycle.sh /dev/shm/t0.txt "echo A" "echo B" "echo C"
# A
# $./cycle.sh /dev/shm/t0.txt "echo A" "echo B" "echo C"
# B
# $./cycle.sh /dev/shm/t0.txt "echo A" "echo B" "echo C"
# C
# $./cycle.sh /dev/shm/t0.txt "echo A" "echo B" "echo C"
# A
#
# The first argument is file name where it will keep the state. 
# In example above, tmpfs at /dev/shm is used.
# If state file does not exists or unreadable it will re-created
# and first command will be invoked

if [ "$#" -le 1 ]; then
    echo "Usage: cycle.sh state_file cmd1 cmd2 ..."
fi

if [ ! -f $1 ]; then
    p=2
else
    s=`cat $1`
    p=`expr $s + 0`
fi

if [ "$p" -gt "$#" ]; then
    p=2
fi

eval ${!p}

n=`expr $p + 1`
rm -f $1
echo $n > $1

exit 0

