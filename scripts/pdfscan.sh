#!/bin/sh

if [ $# -gt 1 ]
then
    outname=$1
else
    outname="scan"
fi
SOURCE="--source ADF -l 3"

startdir=$(pwd)
tmpdir=scan-$RANDOM

cd /tmp
mkdir $tmpdir
cd $tmpdir
echo "################## Scanning ###################"
scanimage -p -x 215.9 -y 279.4 --batch=out%02d.tif --format=tiff --mode Gray --resolution 300 $SOURCE

start=1
cnt=1
tpages=""
for page in $(ls out*.tif); do
    echo "... Converting $page"
    # increase contrast and reduce colordepth
    convert $page -level 15%,85% -depth 2 "b$page"
done

echo "... Converting to PDF"
tiffcp $tpages output.tif
tiff2pdf -z output.tif > $startdir/$outname.pdf

cd ..
echo "################ Cleaning Up ################"
rm -rf $tmpdir
cd $startdir

