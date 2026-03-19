#!/bin/sh
# Weather.pak - launch.sh

# ─── Setup ────────────────────────────────────────────────────────────────────
# Find out where this script lives & what it is called
PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"

# Check if the device is 64-bit
ARCH=arm
uname -m | grep -q '64' && ARCH=arm64

# Create a folder to save settings & cache
export HOME="$SHARED_USERDATA_PATH/$PAK_NAME"
mkdir -p "$HOME"

# Add the tool folders so the system can find them
export PATH="$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin/$ARCH:$PAK_DIR/bin/shared:$PATH"

# Save a record of what happens to a text file for troubleshooting
rm -f "$LOGS_PATH/$PAK_NAME.txt"
exec >>"$LOGS_PATH/$PAK_NAME.txt" 2>&1
set -x

echo "Starting $PAK_NAME"
cd "$PAK_DIR" || exit 1

# ─── Binaries ─────────────────────────────────────────────────────────────────
# Set the names of the tools that draw the screen & keyboard
PRESENTER="minui-presenter-tg5040"
KEYBOARD="minui-keyboard-tg5040"

# ─── Settings ─────────────────────────────────────────────────────────────────
# Function to read a saved setting or return a default value
read_setting() {
    if [ -f "$HOME/$1" ]; then
        cat "$HOME/$1"
        return
    fi
    [ -n "$2" ] && echo "$2"
}

# Function to save a setting
write_setting() {
    echo "$2" > "$HOME/$1"
}

# ─── Location prompt ──────────────────────────────────────────────────────────
# Ask the user for their city
prompt_location() {
    current=$(read_setting location "Cedar Rapids")
    NEW_LOC=$($KEYBOARD \
        --title "Enter city, ZIP, or airport code" \
        --initial-value "$current")
    KB_EXIT=$?

    # If the user typed something & pressed okay, save it
    if [ $KB_EXIT -eq 0 ] && [ -n "$NEW_LOC" ]; then
        write_setting location "$NEW_LOC"
        LOCATION="$NEW_LOC"
        return 0
    fi
    return 1  # The user cancelled
}

# Load saved location, prompt on first launch
LOCATION=$(read_setting location "")
if [ -z "$LOCATION" ]; then
    prompt_location || exit 0
fi

# ─── Fetch ────────────────────────────────────────────────────────────────────
WEATHER_CACHE="$HOME/weather_cache.txt"

# Get the weather from the internet
do_fetch() {
    # Change spaces to plus signs for the web address
    loc_enc=$(echo "$LOCATION" | sed 's/ /+/g')

    $PRESENTER --message "Fetching weather for $LOCATION." --timeout 2

    # &u = USCS units (Fahrenheit, mph). URL stored in a variable so & stays unencoded
    # (unencoded & = new query parameter; %26 would make wttr.in treat it as part of the format string)
    WTTR_URL="http://wttr.in/${loc_enc}?format=%C%7C%t%7C%f%7C%w%7C%h%7C%u&u"
    wget -q -O "$WEATHER_CACHE.tmp" "$WTTR_URL" 2>/dev/null
    WGET_EXIT=$?

    # Stop if the download failed
    if [ $WGET_EXIT -ne 0 ] || [ ! -s "$WEATHER_CACHE.tmp" ]; then
        rm -f "$WEATHER_CACHE.tmp"
        return 1
    fi

    # Stop if the data does not look right
    if ! grep -q '|' "$WEATHER_CACHE.tmp"; then
        rm -f "$WEATHER_CACHE.tmp"
        return 1
    fi

    # Read the downloaded data
    RAW=$(cat "$WEATHER_CACHE.tmp")

    # Split the data into parts & remove extra spaces
    CONDITION=$(echo "$RAW" | cut -d'|' -f1 | xargs)
    TEMP=$(echo "$RAW"      | cut -d'|' -f2 | xargs | tr -d '+')
    FEELS=$(echo "$RAW"     | cut -d'|' -f3 | xargs | tr -d '+')
    WIND=$(echo "$RAW"      | cut -d'|' -f4 | xargs)
    HUMIDITY=$(echo "$RAW"  | cut -d'|' -f5 | xargs)
    UV=$(echo "$RAW"        | cut -d'|' -f6 | xargs)

    # Build the final sentence & save it
    MSG="$LOCATION is currently $CONDITION. It is $TEMP but feels like $FEELS with$WIND winds, $HUMIDITY humidity, & a UV index of $UV."
    printf '%s' "$MSG" > "$WEATHER_CACHE"

    # Delete the temporary file
    rm -f "$WEATHER_CACHE.tmp"
    return 0
}

# ─── Main logic ───────────────────────────────────────────────────────────────
# Try to get the weather
if ! do_fetch; then
    # If it failed & there is no old data, ask to retry
    if [ ! -f "$WEATHER_CACHE" ]; then
        $PRESENTER \
            --message "Could not fetch weather for $LOCATION. Check WiFi is connected & location name is valid." \
            --confirm-button A --confirm-text "RETRY" --confirm-show \
            --cancel-button B  --cancel-text "QUIT"  --cancel-show
        PROMPT_EXIT=$?
        if [ $PROMPT_EXIT -eq 0 ]; then
            do_fetch
        else
            exit 0
        fi
    fi
    # If the retry failed too, tell the user & quit
    if [ ! -f "$WEATHER_CACHE" ]; then
        $PRESENTER \
            --message "No weather data available. Please connect to WiFi & try again." \
            --cancel-button B --cancel-text "QUIT" --cancel-show
        exit 0
    fi
    # If fetching failed but old data exists, it will show the old data
fi

# ─── Display loop ─────────────────────────────────────────────────────────────
# Keep showing the weather until the user quits
while true; do
    $PRESENTER \
        --message "$(cat "$WEATHER_CACHE")" \
        --confirm-button A --confirm-text "REFRESH"  --confirm-show \
        --action-button  X --action-text  "LOCATION" --action-show \
        --cancel-button  B --cancel-text  "QUIT"     --cancel-show

    # Check which button was pressed
    case $? in
        0)  # A — Refresh the weather
            if ! do_fetch; then
                $PRESENTER --message "Refresh failed. Showing cached data." --timeout 3
            fi
            ;;
        4)  # X — Ask for a new location
            if prompt_location; then
                if ! do_fetch; then
                    $PRESENTER --message "Could not fetch weather for $LOCATION." --timeout 3
                fi
            fi
            ;;
        *)  # B — Quit the app
            break
            ;;
    esac
done

exit 0