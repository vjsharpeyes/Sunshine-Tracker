import Toybox.Background;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application.Properties;
import Toybox.Attention;
import Toybox.Lang;

(:background)
class BackgroundService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    // Called when a background event occurs
    function onTemporalEvent() as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);

        // Check if we should skip (after 7:30 PM or before 6 AM)
        var hour = info.hour;
        if (hour >= 19 || (hour == 19 && info.min >= 30) || hour < 6) {
            // Skip to 6 AM next day
            var tomorrow = now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
            var tomorrowInfo = Gregorian.info(tomorrow, Time.FORMAT_SHORT);
            var tomorrowMoment = Gregorian.moment({
                :year => tomorrowInfo.year,
                :month => tomorrowInfo.month,
                :day => tomorrowInfo.day,
                :hour => 6,
                :minute => 0
            });
            Background.registerForTemporalEvent(tomorrowMoment);
            return;
        }

        // Get solar intensity
        var solarIntensity = getSolarIntensity();

        if (solarIntensity != null && solarIntensity >= 10) {
            // Count as sunshine - we sample every 5 minutes, so add 5 minutes
            var dataManager = new DataManager();
            // Note: checkAndResetIfNewDay() is already called in DataManager.initialize()

            // Add 5 minutes of sunshine
            dataManager.addSunshineMinutes(5);

            // Update graph slot based on time of day
            var slotIndex = calculateGraphSlot(info.hour, info.min);
            if (slotIndex >= 0) {
                dataManager.incrementGraphSlot(slotIndex, solarIntensity);
            }

            // Check if we should send a notification
            checkAndSendNotification(dataManager);
        }

        // Schedule next check in 5 minutes
        var nextTime = now.add(new Time.Duration(300)); // 300 seconds = 5 minutes
        Background.registerForTemporalEvent(nextTime);

        // Exit background process - this is required for background service to complete
        Background.exit(null);
    }

    // Get solar intensity from system stats
    private function getSolarIntensity() as Number? {
        var stats = System.getSystemStats();
        if (stats has :solarIntensity) {
            return stats.solarIntensity;
        }
        return null;
    }

    // Calculate which graph slot to update based on time
    // 28 slots from 6 AM to 8 PM (14 hours = 840 minutes)
    // Each slot represents ~30 minutes
    private function calculateGraphSlot(hour as Number, minute as Number) as Number {
        // Convert to minutes since 6 AM
        var minutesSince6AM = (hour - 6) * 60 + minute;

        if (minutesSince6AM < 0 || minutesSince6AM >= 840) {
            return -1; // Outside tracking window
        }

        // 840 minutes / 28 slots = 30 minutes per slot
        var slotIndex = (minutesSince6AM / 30).toNumber();
        return slotIndex;
    }

    // Check if a notification should be sent
    private function checkAndSendNotification(dataManager as DataManager) as Void {
        var notificationInterval = Properties.getValue("notificationInterval");
        if (notificationInterval == null) {
            notificationInterval = 60; // Default to 60 minutes
        }

        var currentMinutes = dataManager.getSunshineMinutes();
        var lastMilestone = dataManager.getLastNotificationMilestone();

        // Calculate which milestone we've reached
        var currentMilestone = (currentMinutes / notificationInterval).toNumber() * notificationInterval;

        // Only notify if we've crossed a new milestone
        if (currentMilestone > lastMilestone && currentMilestone > 0) {
            sendNotification(currentMilestone);
            dataManager.setLastNotificationMilestone(currentMilestone);
        }
    }

    // Send notification to user
    private function sendNotification(minutes as Number) as Void {
        if (Attention has :playTone && Attention has :vibrate) {
            var vibeData = [
                new Attention.VibeProfile(50, 200),  // 50% intensity, 200ms
                new Attention.VibeProfile(0, 100),   // pause 100ms
                new Attention.VibeProfile(50, 200)   // 50% intensity, 200ms
            ];

            try {
                Attention.vibrate(vibeData);
                Attention.playTone(Attention.TONE_ALERT_HI);
            } catch (ex) {
                // Ignore if attention features not available
            }
        }
    }
}
