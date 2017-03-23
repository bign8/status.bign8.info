#!/bin/bash

out=$(python /Users/nathanevans/Documents/main.py)
export IFS=";"
for word in $out; do
    echo $word
done