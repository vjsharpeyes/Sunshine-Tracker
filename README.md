# Sunshine Tracker Widget

A Connect IQ widget for Garmin Fenix 8 Solar (and compatible devices) that tracks daily sun exposure using the watch's built-in solar intensity sensor.

## Features

- **Daily Sunshine Tracking**: Automatically samples solar intensity every 5 minutes and accumulates total sunshine minutes for the day
- **Real-time Display**: Shows current solar intensity percentage and UV index with color coding
- **Visual Graph**: Line graph displaying sunshine intensity across 28 time slots from sunrise to sunset (~30-minute intervals)
- **Smart Notifications**: Configurable milestone alerts (vibration + tone) at 15/30/45/60/90/120 minute intervals
- **Automatic Reset**: Daily data resets at midnight for fresh tracking
- **Background Processing**: Continues tracking even when the widget isn't actively displayed
- **Location-aware**: Uses actual sunrise/sunset times based on your location

## Display Layout

```
┌─────────────────┐
│    Sunshine     │  <- Title
│    125 mins     │  <- Total minutes today
│    Tracking     │  <- Green indicator when solar ≥10%
│                 │
│   ╱╲    ╱╲      │  <- Activity graph
│  ╱  ╲╱╲╱  ╲     │
│ ╱          ╲    │
│────────────────│
│ 6:30a  12p  7:45p│  <- Sunrise/Sunset times
│                 │
│   Solar: 45%    │  <- Current solar intensity
│    UV: 6.2      │  <- UV index (color coded)
└─────────────────┘
```

## How It Works

1. **Background Service**: Every 5 minutes during daylight hours (6 AM - 7:30 PM), the widget samples the solar cell intensity
2. **Sunshine Detection**: When solar intensity is ≥10%, the widget counts those 5 minutes as "sunshine time"
3. **Data Storage**: All data is persisted using `Application.Storage`, surviving widget restarts and watch reboots
4. **Graph Updates**: The intensity values are plotted on a timeline graph showing your sun exposure pattern throughout the day

## Permissions Required

- **SensorHistory**: Access to solar intensity data
- **Background**: Allow background processing for automatic sampling
- **Positioning**: Required for sunrise/sunset calculations

## Supported Devices

- Fenix 7 Pro (No Wi-Fi)
- Fenix 7X
- Fenix 7X Pro (No Wi-Fi)
- Fenix 8 Solar 47mm
- Fenix 8 Solar 51mm

## Installation

1. Build the project using Garmin Connect IQ SDK:
   ```bash
   monkeyc -e -o SunshineV4.iq -f monkey.jungle -y /path/to/developer_key
   ```

2. Copy the `.iq` file to your watch:
   - Connect watch via USB
   - Copy to `GARMIN/Apps` folder
   - Or use Garmin Express to sideload

3. **Important**: Open the widget at least once after installation to activate the background service

## Configuration

Settings can be configured via Garmin Connect Mobile app:
- **Notification Interval**: Choose milestone alerts at 15, 30, 45, 60, 90, or 120 minutes

## Technical Details

- **Sampling Interval**: Every 5 minutes
- **Sunshine Threshold**: Solar intensity ≥10%
- **Graph Slots**: 28 slots covering 14 hours (6 AM to 8 PM)
- **Storage**: Uses `Application.Storage` for persistent data
- **UV Color Coding**:
  - Green: UV < 3 (Low)
  - Yellow: UV 3-5 (Moderate)
  - Orange: UV 6-7 (High)
  - Red: UV ≥ 8 (Very High)

## Development

Built with:
- Garmin Connect IQ SDK
- Monkey C programming language
- Minimum API Level: 5.2.0

## License

MIT License - Feel free to use and modify as needed.

## Author

Sunshine Tracker Contributors

---

*Generated with assistance from Claude Code*
