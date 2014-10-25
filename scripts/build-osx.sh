#!/bin/sh

OWD=`pwd`

if [ ! -f Gateblu.dmg ]; then
  echo "You need a Gateblu.dmg in your current dir"
  exit 1
fi

hdiutil attach Gateblu.dmg

cd /Volumes/Gateblu/Gateblu.app/Contents/Resources/app.nw
git pull
rm -rf node_modules
npm install
gulp
touch /Volumes/Gateblu/Gateblu.app

cd $OWD
bless --folder /Volumes/Gateblu --openfolder /Volumes/Gateblu
sleep 2

hdiutil detach /Volumes/Gateblu
