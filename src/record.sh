#!/bin/sh
#
# General purpose recording script
# Dependencies: ffmpeg, xrandr, awk, sed, sleep
# Usage: record [--display | -d] | [--screencast | -s]

RESOLUTION=$(xrandr | awk '(/current/){print $8 "x" $10 }' | sed 's/,//')

case $1 in
   --display | -d)
      # Forked from https://github.com/dylanaraps/bin/blob/master/scr
      ffmpeg -y \
         -hide_banner \
         -loglevel error \
         -f x11grab \
         -video_size "$RESOLUTION" \
         -i "$DISPLAY" \
         -vframes 1 \
         /mnt/horcrux/downloads/screenshot_"$(date +'%Y-%d_%b-%H_%M_%S')".png
      ;;
   --screencast | -s)
      # Forked from https://github.com/LukeSmithxyz/voidrice/blob/master/.local/bin/dmenurecord
      RECPID=/tmp/recpid
      stop() {
         recpid=$(cat "$RECPID")
         kill -15 "$recpid"
         rm -f "$RECPID"
         sleep 3
         kill -9 "$recpid"
         exit
      }

      [ -f "$RECPID" ] && stop
      ffmpeg \
         -f x11grab \
         -framerate 60 \
         -s "$RESOLUTION" \
         -i "$DISPLAY" \
         -r 30 \
         -f alsa -i default \
         -c:v libx264rgb -crf 0 -preset ultrafast -c:a flac \
         ~/Downloads/screencast_"$(date +'%Y-%d_%b-%H_%M_%S')".mkv &
      echo $! > "$RECPID"
      ;;
   *) exit 1 ;;
esac

# -i :0.0 \
