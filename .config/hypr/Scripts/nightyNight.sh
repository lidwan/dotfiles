#!/bin/bash

# Check if hyprsunset is running
if pgrep -x "hyprsunset" > /dev/null
then
    # If hyprsunset is running, kill it
    pkill hyprsunset
else
    # If hyprsunset is not running, start it in the background
    hyprsunset -t 4500 &
fi

