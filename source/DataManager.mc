import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Manages data storage and retrieval for sunshine tracking
class DataManager {

    // Storage keys
    private const KEY_LAST_DATE = "lastDate";
    private const KEY_SUNSHINE_MINUTES = "sunshineMinutes";
    private const KEY_GRAPH_DATA = "graphData";
    private const KEY_LAST_NOTIFICATION_MILESTONE = "lastNotificationMilestone";

    // Graph configuration
    private const GRAPH_SLOTS = 28; // 28 slots for graph data

    function initialize() {
        checkAndResetIfNewDay();
    }

    // Check if it's a new day and reset data if needed
    function checkAndResetIfNewDay() as Void {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var todayString = today.year.format("%04d") + "-" +
                         today.month.format("%02d") + "-" +
                         today.day.format("%02d");

        var lastDate = Storage.getValue(KEY_LAST_DATE);

        if (lastDate == null || !lastDate.equals(todayString)) {
            // New day - reset all data
            resetDailyData();
            Storage.setValue(KEY_LAST_DATE, todayString);
        }
    }

    // Reset all daily tracking data
    private function resetDailyData() as Void {
        Storage.setValue(KEY_SUNSHINE_MINUTES, 0);

        // Initialize graph data array with zeros
        var graphData = new [GRAPH_SLOTS];
        for (var i = 0; i < GRAPH_SLOTS; i++) {
            graphData[i] = 0;
        }
        Storage.setValue(KEY_GRAPH_DATA, graphData);
        Storage.setValue(KEY_LAST_NOTIFICATION_MILESTONE, 0);
    }

    // Get current sunshine minutes
    function getSunshineMinutes() as Number {
        var minutes = Storage.getValue(KEY_SUNSHINE_MINUTES);
        return minutes != null ? minutes : 0;
    }

    // Increment sunshine minutes by specified amount
    function addSunshineMinutes(minutes as Number) as Void {
        var current = getSunshineMinutes();
        Storage.setValue(KEY_SUNSHINE_MINUTES, current + minutes);
    }

    // Get graph data array
    function getGraphData() as Array {
        var data = Storage.getValue(KEY_GRAPH_DATA);
        if (data == null) {
            // Initialize if not exists
            data = new [GRAPH_SLOTS];
            for (var i = 0; i < GRAPH_SLOTS; i++) {
                data[i] = 0;
            }
            Storage.setValue(KEY_GRAPH_DATA, data);
        }
        return data;
    }

    // Update graph data at specific slot
    function updateGraphSlot(slotIndex as Number, value as Number) as Void {
        if (slotIndex >= 0 && slotIndex < GRAPH_SLOTS) {
            var data = getGraphData();
            data[slotIndex] = value;
            Storage.setValue(KEY_GRAPH_DATA, data);
        }
    }

    // Increment value at specific graph slot
    function incrementGraphSlot(slotIndex as Number, increment as Number) as Void {
        if (slotIndex >= 0 && slotIndex < GRAPH_SLOTS) {
            var data = getGraphData();
            data[slotIndex] = data[slotIndex] + increment;
            Storage.setValue(KEY_GRAPH_DATA, data);
        }
    }

    // Get the last notification milestone that was triggered
    function getLastNotificationMilestone() as Number {
        var milestone = Storage.getValue(KEY_LAST_NOTIFICATION_MILESTONE);
        return milestone != null ? milestone : 0;
    }

    // Set the last notification milestone
    function setLastNotificationMilestone(milestone as Number) as Void {
        Storage.setValue(KEY_LAST_NOTIFICATION_MILESTONE, milestone);
    }

    // Get number of graph slots
    function getGraphSlotCount() as Number {
        return GRAPH_SLOTS;
    }
}
