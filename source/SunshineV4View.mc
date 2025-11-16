import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Weather;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Position;
import Toybox.Background;

class SunshineV4View extends WatchUi.View {

    private var _dataManager as DataManager?;

    function initialize() {
        View.initialize();
        var app = getApp();
        _dataManager = app.getDataManager();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // No layout needed - custom drawing
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Ensure background service stays registered every time widget updates
        ensureBackgroundRegistered();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // Clear screen with black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_dataManager == null) {
            return;
        }

        // Calculate safe margins (10% from edges for round watch)
        var margin = width * 0.1;

        // Get data
        var sunshineMinutes = _dataManager.getSunshineMinutes();
        var solarIntensity = getSolarIntensity();
        var uvIndex = getUVIndex();
        var graphData = _dataManager.getGraphData();

        // Top section: Sunshine title and minutes
        var topY = margin.toNumber() + 5;
        drawSunshineInfo(dc, centerX, topY, sunshineMinutes);

        // Middle section: Graph
        var graphY = height * 0.35;
        var graphHeight = height * 0.3;
        drawGraph(dc, margin.toNumber(), graphY.toNumber(), width - (2 * margin).toNumber(), graphHeight.toNumber(), graphData);

        // Bottom section: Solar % and UV index
        var bottomY = height - margin.toNumber() - 40;
        drawBottomInfo(dc, centerX, bottomY.toNumber(), solarIntensity, uvIndex);
    }

    // Draw sunshine title and total minutes
    private function drawSunshineInfo(dc as Dc, centerX as Number, y as Number, minutes as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Title
        dc.drawText(centerX, y, Graphics.FONT_SMALL, "Sunshine", Graphics.TEXT_JUSTIFY_CENTER);

        // Minutes with debug info
        var minutesText = minutes.format("%d") + " mins";
        dc.drawText(centerX, y + 20, Graphics.FONT_MEDIUM, minutesText, Graphics.TEXT_JUSTIFY_CENTER);

        // Debug: Show if background is tracking
        var solarNow = getSolarIntensity();
        if (solarNow != null && solarNow >= 10) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y + 40, Graphics.FONT_XTINY, "Tracking", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Debug: Show last background event time
        var lastEventTime = Background.getLastTemporalEventTime();
        if (lastEventTime != null) {
            var eventInfo = Gregorian.info(lastEventTime, Time.FORMAT_SHORT);
            var eventText = "Last: " + eventInfo.hour.format("%d") + ":" + eventInfo.min.format("%02d");
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y + 55, Graphics.FONT_XTINY, eventText, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y + 55, Graphics.FONT_XTINY, "No BG Event", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Draw the graph
    private function drawGraph(dc as Dc, x as Number, y as Number, width as Number, height as Number, data as Array) as Void {
        // Find max value for scaling
        var maxValue = 1; // Minimum 1 to avoid division by zero
        for (var i = 0; i < data.size(); i++) {
            if (data[i] > maxValue) {
                maxValue = data[i];
            }
        }

        // Get sunrise and sunset times
        var sunTimes = getSunriseSunset();
        var sunriseText = sunTimes[0];
        var sunsetText = sunTimes[1];
        var noonText = "12p";

        // Draw time labels
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + height + 5, Graphics.FONT_XTINY, sunriseText, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(x + width / 2, y + height + 5, Graphics.FONT_XTINY, noonText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x + width, y + height + 5, Graphics.FONT_XTINY, sunsetText, Graphics.TEXT_JUSTIFY_RIGHT);

        // Draw graph baseline
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y + height, x + width, y + height);

        // Draw graph data as connected lines
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var slotWidth = width.toFloat() / data.size();

        for (var i = 0; i < data.size() - 1; i++) {
            var x1 = x + (i * slotWidth).toNumber();
            var y1 = y + height - ((data[i].toFloat() / maxValue) * height).toNumber();
            var x2 = x + ((i + 1) * slotWidth).toNumber();
            var y2 = y + height - ((data[i + 1].toFloat() / maxValue) * height).toNumber();

            dc.drawLine(x1, y1, x2, y2);
        }

        // Draw dots at hour markers (every ~2 slots since 28 slots / 14 hours)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < data.size(); i += 2) {
            var dotX = x + (i * slotWidth).toNumber();
            var dotY = y + height - ((data[i].toFloat() / maxValue) * height).toNumber();
            dc.fillCircle(dotX, dotY, 2);
        }
    }

    // Draw solar intensity and UV index at bottom
    private function drawBottomInfo(dc as Dc, centerX as Number, y as Number, solarIntensity as Number?, uvIndex as Number?) as Void {
        // Solar intensity
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var solarText = "Solar: ";
        if (solarIntensity != null) {
            solarText += solarIntensity.format("%d") + "%";
        } else {
            solarText += "--";
        }
        dc.drawText(centerX, y, Graphics.FONT_SMALL, solarText, Graphics.TEXT_JUSTIFY_CENTER);

        // UV index with color coding
        if (uvIndex != null) {
            var uvColor = getUVColor(uvIndex);
            dc.setColor(uvColor, Graphics.COLOR_TRANSPARENT);

            var uvText = "UV: " + uvIndex.format("%.1f");
            dc.drawText(centerX, y + 25, Graphics.FONT_SMALL, uvText, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y + 25, Graphics.FONT_SMALL, "UV: --", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Get current solar intensity
    private function getSolarIntensity() as Number? {
        var stats = System.getSystemStats();
        if (stats has :solarIntensity) {
            return stats.solarIntensity;
        }
        return null;
    }

    // Get current UV index
    private function getUVIndex() as Number? {
        var conditions = Weather.getCurrentConditions();
        if (conditions != null && conditions has :uvIndex && conditions.uvIndex != null) {
            return conditions.uvIndex;
        }
        return null;
    }

    // Get color for UV index
    private function getUVColor(uvIndex as Number) as Number {
        if (uvIndex < 3) {
            return Graphics.COLOR_GREEN;
        } else if (uvIndex < 6) {
            return Graphics.COLOR_YELLOW;
        } else if (uvIndex < 8) {
            return Graphics.COLOR_ORANGE;
        } else {
            return Graphics.COLOR_RED;
        }
    }

    // Get sunrise and sunset times as formatted strings
    private function getSunriseSunset() as Array<String> {
        // Try to get sunrise/sunset from Weather API
        var conditions = Weather.getCurrentConditions();
        if (conditions != null) {
            var sunriseStr = "6a";
            var sunsetStr = "8p";

            if (conditions has :sunrise && conditions.sunrise != null) {
                // Convert to local time using FORMAT_SHORT which uses local timezone
                var sunriseInfo = Gregorian.info(conditions.sunrise, Time.FORMAT_SHORT);
                // Validate the hour is reasonable (between 4am and 9am typically)
                if (sunriseInfo.hour >= 4 && sunriseInfo.hour <= 9) {
                    sunriseStr = formatTime(sunriseInfo.hour, sunriseInfo.min);
                }
            }

            if (conditions has :sunset && conditions.sunset != null) {
                // Convert to local time using FORMAT_SHORT which uses local timezone
                var sunsetInfo = Gregorian.info(conditions.sunset, Time.FORMAT_SHORT);
                // Validate the hour is reasonable (between 4pm and 10pm typically)
                if (sunsetInfo.hour >= 16 && sunsetInfo.hour <= 22) {
                    sunsetStr = formatTime(sunsetInfo.hour, sunsetInfo.min);
                }
            }

            return [sunriseStr, sunsetStr];
        }

        // Fallback to default times if weather data not available
        return ["6a", "8p"];
    }

    // Format hour and minute to time string (e.g., "6:30a" or "7:15p")
    private function formatTime(hour as Number, minute as Number) as String {
        var ampm = "a";
        var displayHour = hour;

        if (hour >= 12) {
            ampm = "p";
            if (hour > 12) {
                displayHour = hour - 12;
            }
        }
        if (hour == 0) {
            displayHour = 12;
        }

        if (minute == 0) {
            return displayHour.format("%d") + ampm;
        } else {
            return displayHour.format("%d") + ":" + minute.format("%02d") + ampm;
        }
    }

    // Ensure background service is registered every time widget updates
    private function ensureBackgroundRegistered() as Void {
        var now = Time.now();

        // Schedule background event 5 minutes from now to comply with the minimum interval
        var nextTime = now.add(new Time.Duration(300)); // 300 seconds = 5 minutes

        try {
            Background.registerForTemporalEvent(nextTime);
        } catch (ex) {
            // If registration fails (too soon after last event), that's okay
            // The existing registration will continue
        }
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
    }
}
