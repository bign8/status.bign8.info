#! /bin/bash -ex

DKR="docker run --rm -it -w /mnt -v $PWD:/mnt"
$DKR xzyfer/docker-libsass:3.2.5 --style compressed -m web/sass/style.sass web/static/style.css
$DKR google/dart:2 bash -xc "pub get && dart --disable-analytics compile js -m -o web/static/main.dart.js web/dart/main.dart"
go build -o status -ldflags="-s -w" -v .
#gzip -f status
#scp status.gz me.bign8.info:/opt/bign8
#sudo rm -rf build .pub .packages pubspec.lock web/style.css* status.gz
