#! /bin/bash -ex

case $1 in
  dart)
    dart --disable-analytics
    dart pub get
    dart pub run build_runner build --release --output build
    exit 0
    ;;
esac

DKR="docker run --rm -it -w /mnt -v $PWD:/mnt"
$DKR google/dart:2 ./ship.sh dart
go build -o status -ldflags="-s -w" -v .
gzip -f status
scp status.gz me.bign8.info:/opt/bign8
ssh me.bign8.info -- sudo systemctl restart status
rm status.gz
