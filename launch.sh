#!/bin/sh
# Weather.pak - launch.sh

# ─── Setup ────────────────────────────────────────────────────────────────────
# Find out where this script lives & what it is called
PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"

# Create a folder to save settings & cache
export HOME="$SHARED_USERDATA_PATH/$PAK_NAME"
mkdir -p "$HOME"

# Add the tool folders so the system can find them
export PATH="$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin/shared:$PATH"

# Save a record of what happens to a text file for troubleshooting
rm -f "$LOGS_PATH/$PAK_NAME.txt"
mkdir -p "$LOGS_PATH" # Ensure the logs folder exists before redirecting output
exec >>"$LOGS_PATH/$PAK_NAME.txt" 2>&1
set -x

echo "Starting $PAK_NAME"
cd "$PAK_DIR" || exit 1
echo 1 > /tmp/stay_awake # Prevent the device from sleeping while the app is running
# Ensure the stay_awake file is deleted & the presenter process is killed when the app exits
trap 'rm -f /tmp/stay_awake "$WEATHER_CACHE.tmp"; killall $PRESENTER 2>/dev/null' EXIT INT TERM HUP QUIT

# ─── Binaries ─────────────────────────────────────────────────────────────────
# Set the names of the tools that draw the screen & keyboard
PRESENTER="minui-presenter-tg5040"
KEYBOARD="minui-keyboard-tg5040"

# ─── Preset locations ─────────────────────────────────────────────────────────
# Format: "City Name|units" where units is u=imperial, m=metric.
# One entry is picked at random to pre-fill the keyboard on first launch.
PRESET_LOCATIONS="\
Utqiagvik, AK|u
Phoenix, AZ|u
Denver, CO|u
Chicago, IL|u
New Orleans, LA|u
Miami, FL|u
New York, NY|u
Seattle, WA|u
Honolulu, HI|u
Reykjavik, Iceland|m
London, UK|m
Kyiv, Ukraine|m
Kopaonik, Serbia|m
Dubai, UAE|m
Mumbai, India|m
Singapore|m
Ushuaia, Argentina|m"

# Pick a random line from the preset list
random_preset() {
    echo "$PRESET_LOCATIONS" | awk 'NF > 0 { lines[NR] = $0 } END { srand(); print lines[int(rand() * NR) + 1] }'
}

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

# ─── Background color ─────────────────────────────────────────────────────────
# Map the wttr.in condition name to a background color.
# Lowercased first so casing differences never cause a miss.
get_bg_color() {
    _c=$(echo "$1" | tr 'A-Z' 'a-z')
    case "$_c" in
        "sunny"|"clear")
            echo "#e2a42b" ;;
        "partly cloudy")
            echo "#8bb8d6" ;;
        "cloudy")
            echo "#8c92ac" ;;
        "overcast"|"very cloudy")
            echo "#5e6472" ;;
        # Fog & low visibility
        "fog"|"mist"|"haze"|"smoke")
            echo "#aeb5c2" ;;
        "freezing fog")
            echo "#c2cdd6" ;;
        "patches of fog, mist")
            echo "#c8cdd4" ;;
        # Dust & sand
        "low drifting sand"|"widespread dust")
            echo "#c4a35a" ;;
        # Drizzle
        "drizzle"|"light drizzle"|"light drizzle and rain"|"light drizzle, mist")
            echo "#6a9fb5" ;;
        # Light rain & showers
        "light showers"|"light rain shower"|"light rain shower, mist"|\
        "patchy light drizzle"|"patchy rain nearby"|\
        "shower in vicinity")
            echo "#4ca8a1" ;;
        "rain shower"|"light rain shower, rain shower")
            echo "#5c9aab" ;;
        "light rain"|"rain"|"light rain, mist"|"rain, mist, light rain")
            echo "#3a86ff" ;;
        "moderate rain at times"|"moderate or heavy rain shower")
            echo "#2d6a8f" ;;
        "heavy showers")
            echo "#2b7a78" ;;
        "heavy rain"|"heavy rain, mist")
            echo "#003049" ;;
        # Mixed rain & frozen
        "light rain and snow"|\
        "light rain and snow shower"|\
        "light rain shower, light rain and snow shower"|\
        "light rain shower, rain and small hail/snow pallets shower")
            echo "#7a9eb5" ;;
        # Snow & sleet
        "light sleet"|"light sleet showers"|"light freezing rain"|"light freezing rain, mist"|\
        "light snow"|"light snow shower"|"light snow showers"|"light snow, mist"|\
        "light snow, low drifting snow")
            echo "#9eb5ba" ;;
        "moderate snow"|"snow"|"snow, mist")
            echo "#a8c4d4" ;;
        "heavy snow"|"heavy snow showers"|"snow, blowing snow")
            echo "#b4d4e0" ;;
        # Thunderstorms — lighter variants first, full storm last
        "light rain with thunderstorm"|\
        "light rain shower, thunderstorm"|\
        "patchy light rain in area with thunder")
            echo "#6a3d8f" ;;
        "thunderstorm in vicinity")
            echo "#5c3570" ;;
        "thundery showers"|"thundery heavy rain"|"thundery snow showers"|\
        "thunderstorm"|"thundery outbreaks in nearby"|\
        "thunderstorm, rain with thunderstorm"|\
        "haze, rain with thunderstorm"|\
        "heavy rain shower, heavy rain with thunderstorm, rain shower"|\
        "light rain with thunderstorm, rain with thunderstorm"|\
        "rain with thunderstorm, light rain shower"|\
        "smoke, rain with thunderstorm")
            echo "#4a148c" ;;
        *)
            echo "#000000" ;;
    esac
}

# ─── Location prompt ──────────────────────────────────────────────────────────
# Ask the user for their city, then ask imperial vs metric.
prompt_location() {
    # Pre-fill with saved location, or a random preset city on first launch
    prefill=$(read_setting location "")
    if [ -z "$prefill" ]; then
        prefill=$(random_preset | cut -d'|' -f1)
    fi

    NEW_LOC=$($KEYBOARD \
        --title "Enter city, ZIP, or airport code" \
        --initial-value "$prefill")
    KB_EXIT=$?

    # User cancelled the keyboard
    [ $KB_EXIT -ne 0 ] || [ -z "$NEW_LOC" ] && return 1

    # Ask imperial vs metric
    $PRESENTER \
        --message "Use Imperial or Metric units for $NEW_LOC?" \
        --confirm-button A --confirm-text "IMPERIAL" --confirm-show \
        --action-button  X --action-text  "METRIC"   --action-show \
        --cancel-button  B --cancel-text  "CANCEL"   --cancel-show
    UNITS_EXIT=$?

    case $UNITS_EXIT in
        0) NEW_UNITS="u" ;;  # A — Imperial
        4) NEW_UNITS="m" ;;  # X — Metric
        *) return 1 ;;       # B — Cancel
    esac

    write_setting location "$NEW_LOC"
    write_setting units    "$NEW_UNITS"
    LOCATION="$NEW_LOC"
    UNITS_FLAG="$NEW_UNITS"
    return 0
}

# Load saved location & units; prompt on first launch
LOCATION=$(read_setting location "")
UNITS_FLAG=$(read_setting units "")
if [ -z "$LOCATION" ] || [ -z "$UNITS_FLAG" ]; then
    prompt_location || exit 0
fi

# ─── Fetch ────────────────────────────────────────────────────────────────────
WEATHER_CACHE="$HOME/weather_cache.txt"
CONDITION_CACHE="$HOME/condition_cache.txt"

# Get the weather from the internet
do_fetch() {
    # Change spaces to plus signs for the web address
    loc_enc=$(echo "$LOCATION" | sed 's/ /+/g')

    $PRESENTER --message "Fetching weather for $LOCATION." \
        --message-alignment bottom &
    PRESENTER_PID=$!

    # UNITS_FLAG is either u (imperial) or m (metric)
    # URL stored in a variable so & stays unencoded
    # (unencoded & = new query parameter; %26 would make wttr.in treat it as part of the format string)
    WTTR_URL="http://wttr.in/${loc_enc}?format=%C%7C%t%7C%f%7C%w%7C%h%7C%u&${UNITS_FLAG}"
    wget -q -O "$WEATHER_CACHE.tmp" "$WTTR_URL" 2>/dev/null
    WGET_EXIT=$?

    kill $PRESENTER_PID 2>/dev/null
    sleep 1
    kill -9 $PRESENTER_PID 2>/dev/null
    wait $PRESENTER_PID 2>/dev/null

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
    printf '%s' "$MSG"       > "$WEATHER_CACHE"
    printf '%s' "$CONDITION" > "$CONDITION_CACHE"

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
    BG_COLOR=$(get_bg_color "$(cat "$CONDITION_CACHE" 2>/dev/null)")

    $PRESENTER \
        --message "$(cat "$WEATHER_CACHE")" \
        --background-color "$BG_COLOR" \
        --show-pill \
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