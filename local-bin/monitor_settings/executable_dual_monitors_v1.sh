#!/bin/bash

# Function to get the list of connected displays
get_connected_displays() {
    xrandr --query | grep " connected" | awk '{ print $1 }'
}

# Get the list of currently connected displays
displays=($(get_connected_displays))
display_count=${#displays[@]}

if [ "$display_count" -eq 0 ]; then
    echo "No displays connected."
    exit 1
fi

# Array to hold resolutions
resolutions=($(xrandr | grep -oP "\d{3,4}x\d{3,4}" | sort -u))

# Function to configure a single monitor
configure_monitor() {
    local monitor=$1

    # Step 2: Turn on/off the monitor
    state=$(printf 'On\nOff' | rofi -dmenu -p "Turn $monitor On or Off")
    if [[ $state == "On" ]]; then
        xrandr --output "$monitor" --auto  # Turn on
    else
        xrandr --output "$monitor" --off  # Turn off
        return
    fi

    # Step 3: Set the monitor's resolution
    resolution=$(printf '%s\n' "${resolutions[@]}" | rofi -dmenu -p "Select Resolution for $monitor")
    if [[ " ${resolutions[@]} " =~ " $resolution " ]]; then
        xrandr --output "$monitor" --mode "$resolution"
    else
        echo "Invalid resolution selection for $monitor."
        return
    fi

    # Step 4: Set orientation for the monitor
    orientation=$(printf 'Horizontal\nVertical\nSet to Normal' | rofi -dmenu -p "Set orientation for $monitor")
    if [[ $orientation == "Horizontal" ]]; then
        xrandr --output "$monitor" --rotate normal  # Set to Horizontal
    elif [[ $orientation == "Vertical" ]]; then
        xrandr --output "$monitor" --rotate right  # Set to Vertical
    elif [[ $orientation == "Set to Normal" ]]; then
        xrandr --output "$monitor" --rotate normal  # Reset to Normal
    else
        echo "Invalid orientation selection for $monitor."
        return
    fi

    # Step 5: Set relative position with another monitor
    relative_monitor=$(printf '%s\n' "${displays[@]}" | grep -v "$monitor" | rofi -dmenu -p "Set position of $monitor relative to (select a different monitor or leave empty to skip):")
    if [ -n "$relative_monitor" ]; then
        position=$(printf 'Above\nBelow\nLeft\nRight' | rofi -dmenu -p "Set position of $monitor relative to $relative_monitor")
        if [[ $position == "Above" ]]; then
            xrandr --output "$monitor" --auto --above "$relative_monitor"
        elif [[ $position == "Below" ]]; then
            xrandr --output "$monitor" --auto --below "$relative_monitor"
        elif [[ $position == "Left" ]]; then
            xrandr --output "$monitor" --auto --left-of "$relative_monitor"
        elif [[ $position == "Right" ]]; then
            xrandr --output "$monitor" --auto --right-of "$relative_monitor"
        else
            echo "Invalid position selection for $monitor."
        fi
    fi
}

# Step 1: Select which monitor to configure
monitor_to_configure=$(printf '%s\n' "${displays[@]}" | rofi -dmenu -p "Select a monitor to configure")
if [[ ! " ${displays[@]} " =~ " $monitor_to_configure " ]]; then
    echo "Invalid monitor selection."
    exit 1
fi

# Configure the selected monitor
configure_monitor "$monitor_to_configure"
