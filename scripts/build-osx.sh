#!/bin/sh

OWD=`pwd`

hdiutil attach Gateblu.dmg

cd /Volumes/Gateblu/Gateblu.app/Contents/Resources/app.nw
git pull
rm -rf node_modules
cp -r $OWD/node_modules .

cd $OWD
sleep 2

hdiutil detach /Volumes/Gateblu
