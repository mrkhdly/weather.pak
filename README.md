# weather.pak

A simple weather tool for the TrimUI Brick running [MinUI](https://github.com/shauninman/MinUI) / [NextUI](https://github.com/LoveRetro/NextUI). Shows current conditions for any city, ZIP code, or airport code. Requires a WiFi connection.

Weather data is pulled from [wttr.in](https://wttr.in).

> **Device support:** This was built and tested on the TrimUI Brick / Brick Hammer only. It may or may not work on other MinUI / NextUI devices and has not been tested on any of them.

---

## What it does

- Shows current condition, temperature, feels-like, wind, humidity, and UV index
- Supports imperial and metric units
- Saves your location and unit preference between sessions
- Background color shifts to match the current conditions
- On first launch, pre-fills the keyboard with a random city to show you the format

---

## Installation

1. Go to the [Releases](../../releases) page and download the latest `weather.pak.zip`
2. Unzip it -- you should get a folder called `weather.pak`
3. Copy `weather.pak` to your SD card at:
   ```
   /Tools/tg5040/
   ```
4. Put the SD card back in your Brick and launch Weather from the Tools menu

---

## Usage

When you open the pak it will ask for a location if you have not set one yet. Type a city name, ZIP code, or airport code and press A to confirm.

You will then be asked whether you want imperial or metric units.

On the weather screen:

| Button | Action |
|--------|--------|
| A | Refresh weather |
| X | Change location |
| B | Quit |

---

## Configuration

Settings are saved automatically when you enter a location or change units. There is no config file to edit by hand.

Your preferences are stored at:
```
/mnt/SDCARD/.userdata/shared/Weather/
```

To reset to defaults, delete that folder from your SD card.

---

## Credits

- [josegonzalez/minui-presenter](https://github.com/josegonzalez/minui-presenter) -- screen display
- [josegonzalez/minui-keyboard](https://github.com/josegonzalez/minui-keyboard) -- on-screen keyboard
- [wttr.in](https://wttr.in) -- weather data
