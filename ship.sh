#! /bin/bash -ex

DKR="docker run --rm -it -w /mnt -v $PWD:/mnt"
time $DKR xzyfer/docker-libsass:3.2.5 --style compressed -m web/style.sass web/style.css
#$DKR google/dart:1 bash -c "pub get && pub build"
time $DKR google/dart:2 bash -xc "pub get && dart --disable-analytics compile js -m -o web/main.dart.js web/main.dart"
#sudo rm -rf build/web/packages build/web/style.sass
go build -o status -ldflags="-s -w" -v .
#gzip -f status
#scp status.gz me.bign8.info:/opt/bign8
#sudo rm -rf build .pub .packages pubspec.lock web/style.css* status.gz
