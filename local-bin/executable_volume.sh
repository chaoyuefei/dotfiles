#!/bin/bash

# Define the theme path
ROFI_THEME_PATH="$HOME/.config/polybar/blocks/scripts/rofi/launcher.rasi"

# Function to change the output sink
change_output_sink() {
    # List available sinks and format names
    sinks=$(pactl list short sinks | awk '{print $2}' | sed 's/alsa.output.//g') # Remove prefix for readability
    chosen_sink=$(echo "$sinks" | rofi -dmenu -i -p " " -theme "$ROFI_THEME_PATH")
    
    if [ -n "$chosen_sink" ]; then
        # Find and set the default sink based on the readable name
        sink_index=$(pactl list short sinks | grep "$chosen_sink" | awk '{print $1}')
        pactl set-default-sink "$sink_index"
    fi
}

# Function to change the input source
change_input_source() {
    # List available sources and format names
    sources=$(pactl list short sources | awk '{print $2}' | sed 's/alsa.input.//g') # Remove prefix for readability
    chosen_source=$(echo "$sources" | rofi -dmenu -i -p "Select Input Source" -theme "$ROFI_THEME_PATH")
    
    if [ -n "$chosen_source" ]; then
        # Find and set the default source based on the readable name
        source_index=$(pactl list short sources | grep "$chosen_source" | awk '{print $1}')
        pactl set-default-source "$source_index"
    fi
}

# Main menu options
options="Change Output Source  \nChange Input Source   \nOpen Setting  \nExit"
chosen=$(echo -e "$options" | rofi -dmenu -i -p " " -theme "$ROFI_THEME_PATH")

case $chosen in
    "Change Output Source  ")
        change_output_sink
        ;;
    "Change Input Source   ")
        change_input_source
        ;;
    "Open Setting  ")
        pavucontrol &
        ;;
    "Exit")
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
