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

# Prepare layout options
layouts=("Single" "Mirrored")
extend_options=()

# Combine extend options with directions
for display in "${displays[@]:1}"; do  # Only create extend options for external displays
    extend_options+=("Extend with $display above")
    extend_options+=("Extend with $display below")
    extend_options+=("Extend with $display left")
    extend_options+=("Extend with $display right")
done

# Use Rofi to select a layout option
chosen=$(printf '%s\n' "${layouts[@]}" "${extend_options[@]}" | rofi -dmenu -p "Select Display Layout")

# If needed, collect resolution preference via Rofi
resolution=$(xrandr | grep -oP "\d{3,4}x\d{3,4}" | sort -u | rofi -dmenu -p "Select Resolution" -lines 10)

# Apply the selected layout
case $chosen in
    "Single")
        # Set the first display as the only active display, turning off others
        for display in "${displays[@]}"; do
            if [ "$display" != "${displays[0]}" ]; then
                xrandr --output "$display" --off
            fi
        done
        xrandr --output "${displays[0]}" --auto --primary --mode "$resolution"
        ;;
    "Mirrored")
        # Mirror all displays to the primary one with the selected resolution
        for display in "${displays[@]}"; do
            xrandr --output "$display" --mode "$resolution" --same-as "${displays[0]}"
        done
        ;;
    Extend\ with\ *)
        # Extract the display name and direction from the chosen string
        display_to_extend=$(echo "$chosen" | awk '{ print $3 }')
        direction=$(echo "$chosen" | awk '{ print $4 }')

        # Check if the display to extend is valid
        if [[ " ${displays[@]} " =~ " $display_to_extend " ]]; then
            # Apply the selected direction with resolution
            case $direction in
                above)
                    xrandr --output "${displays[0]}" --auto --primary \
                           --mode "$resolution" \
                           --output "$display_to_extend" --auto --above "${displays[0]}" --mode "$resolution"
                    ;;
                below)
                    xrandr --output "${displays[0]}" --auto --primary \
                           --mode "$resolution" \
                           --output "$display_to_extend" --auto --below "${displays[0]}" --mode "$resolution"
                    ;;
                left)
                    xrandr --output "${displays[0]}" --auto --primary \
                           --mode "$resolution" \
                           --output "$display_to_extend" --auto --left-of "${displays[0]}" --mode "$resolution"
                    ;;
                right)
                    xrandr --output "${displays[0]}" --auto --primary \
                           --mode "$resolution" \
                           --output "$display_to_extend" --auto --right-of "${displays[0]}" --mode "$resolution"
                    ;;
                *)
                    echo "Invalid direction selection."
                    exit 1
                    ;;
            esac
        else
            echo "Invalid display selection."
            exit 1
        fi
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac