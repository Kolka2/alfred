#!/bin/sh
#
# Queues up a file on mpv

MPVFIFO=/tmp/mpvfifo

[ -e $MPVFIFO ] || mkfifo $MPVFIFO
if pidof mpv; then
   echo loadfile "$1" append-play > $MPVFIFO
else
   mpv --input-file="$MPVFIFO" "$1" > /dev/null 2>&1 &
fi
