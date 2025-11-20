#!/bin/sh

set -e

# Remove previous apk build
rm -f /output/openbor.apk

# Convert icons
convert /icon.png -resize 72x72 /openbor-android/res/drawable-hdpi/icon.png
convert /icon.png -resize 36x36 /openbor-android/res/drawable-ldpi/icon.png
convert /icon.png -resize 48x48 /openbor-android/res/drawable-mdpi/icon.png

cp /bor.pak /openbor-android/assets/bor.pak

java -jar /apktool/apktool_2.12.1.jar b /openbor-android -o /output/OpenBOR-unsigned.apk
