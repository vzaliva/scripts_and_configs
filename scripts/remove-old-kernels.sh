#!/bin/bash

kernelver=$(uname -r | sed -r 's/-[a-z]+//')
unused=`dpkg -l linux-{image,headers}-"[0-9]*" | awk '/ii/{print $2}' | grep -ve $kernelver`
echo "Your current kernel is version is $kernelver"
if [ -z "$unused" ]; then
    echo "No old kernels to remove."
    exit 0
fi

echo "The following packages could be removed:"
echo
for p in $unused
do
    echo "    $p"
done
echo 

read -p "Proceed [y/N]? " -n 1 -r REPLY
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing"
    sudo apt-get purge  $unused
    exit 0
fi
echo "Not removing"
exit 1
