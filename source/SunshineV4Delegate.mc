import Toybox.Lang;
import Toybox.WatchUi;

class SunshineV4Delegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new SunshineV4MenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}