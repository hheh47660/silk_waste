#!/bin/bash

export XDG_RUNTIME_DIR=/run/user/1000
export PIPEWIRE_RUNTIME_DIR=/run/user/1000
export PULSE_SERVER=unix:/run/user/1000/pulse/native

BATTERY_LEVEL=$(/home/sanko/.local/share/omarchy/bin/omarchy-battery-remaining)
OLD_BATTERY_STATE=$( upower -i $(upower -e | grep bat) | grep state | awk '{print $2}')
ON_CHARGING_SOUND="/usr/share/sounds/freedesktop/stereo/service-login.oga"



while [[ 1 ]]; do
        CURRENT_BATTERY_STATE=$( upower -i $(upower -e | grep bat) | grep state | awk '{print $2}')
        echo "Battery" $CURRENT_BATTERY_STATE     
        if ([ $CURRENT_BATTERY_STATE == "charging" ] || [ $CURRENT_BATTERY_STATE == "fully-charged" ]) && [ $OLD_BATTERY_STATE == "discharging" ]; then
                if !([[ $CURRENT_BATTERY_STATE == "charging" && $OLD_BATTERY_STATE == "fully-charged" ]]); then #avoid playing when goiing from  -| charging->fully-charged
                        pw-play $ON_CHARGING_SOUND
                        OLD_BATTERY_STATE=$CURRENT_BATTERY_STATE
                        echo "Play sound"
                fi 
        fi
        if [[ $CURRENT_BATTERY_STATE == "discharging" ]]; then
                OLD_BATTERY_STATE=$CURRENT_BATTERY_STATE
        fi
        sleep 1
done
