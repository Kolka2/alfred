#!/bin/sh
#
# Monitors Battery level,
# Blocks Charging on High battery level
# Notifies on low levels
# Shuts down on dangerous levels
# It also notifies on Plug and Unplug (Using a supplimental udev rule)

case $1 in
   --block-charge)
      config="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
      if [ "$2" = true ]; then
         echo 1
      else
         echo 0
      fi | doas tee $config > /dev/null
      ;;
   --monitor)
      [ "$(cat /sys/class/power_supply/ADP?/online)" = 1 ] && exit
      set -- /sys/class/power_supply/BAT?/capacity
      read -r cap < "$1"
      if [ "$cap" -lt 10 ]; then
         leavex -s
         # systemctl poweroff
         # systemctl hibernate
      elif [ "$cap" -lt 20 ]; then
         notify-send -t 0 -i "$ICONS"/dying.png 'Low Battery!'
      elif [ "$cap" -lt 90 ]; then
         $0 --block-charge false
      else
         $0 --block-charge true
      fi
      ;;
   --plugged)
      # libnotify environment variables
      # export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

      read -r DISPLAY < /tmp/DISPLAY
      export DISPLAY
      export XAUTHORITY=~/.config/X11/Xauthority
      export ICONS=~/.local/share/icons/system

      if [ "$2" = true ]; then
         notify-send -t 1000 -i "$ICONS"/charging.png "Charging"
      else
         notify-send -t 1000 -i "$ICONS"/discharging.png "Discharging"
      fi
      # doas -n -- canberra-gtk-play -i device-removed &
      ;;
esac
