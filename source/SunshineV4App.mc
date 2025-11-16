import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.Time;
import Toybox.System;

class SunshineV4App extends Application.AppBase {

    private var _dataManager as DataManager?;

    function initialize() {
        AppBase.initialize();
        _dataManager = new DataManager();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // Note: checkAndResetIfNewDay() is already called in DataManager.initialize()
        // No need to call it again here

        // Register background service if not already registered
        scheduleNextBackgroundCheck();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new SunshineV4View() ];
    }

    // Return the service delegate for background processing
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [ new BackgroundService() ];
    }

    // Called when background data is available
    function onBackgroundData(data as Application.PersistableType) as Void {
        // Background requested UI update - request view update
        WatchUi.requestUpdate();
    }

    // Get the data manager instance
    function getDataManager() as DataManager? {
        return _dataManager;
    }

    // Schedule the next background check
    private function scheduleNextBackgroundCheck() as Void {
        var now = Time.now();
        var nextTime = now.add(new Time.Duration(300)); // 5 minutes from now
        Background.registerForTemporalEvent(nextTime);
    }
}

function getApp() as SunshineV4App {
    return Application.getApp() as SunshineV4App;
}