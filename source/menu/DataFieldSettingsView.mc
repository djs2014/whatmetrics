import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

var gExitedMenu as Boolean = false;

//! Initial view for the settings
class DataFieldSettingsView extends WatchUi.View {
  //! Constructor
  function initialize() {
    View.initialize();
  }

  //! Update the view
  //! @param dc Device context
  function onUpdate(dc as Dc) as Void {
    dc.clearClip();
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    var mySettings = System.getDeviceSettings();
    var version = mySettings.monkeyVersion;
    var versionString = Lang.format("$1$.$2$.$3$", version);

    dc.drawText(
      dc.getWidth() / 2,
      dc.getHeight() / 2 - 30,
      Graphics.FONT_SMALL,
      "Press Menu \nfor settings \nCIQ " + versionString,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }
}

//! Handle opening the settings menu
class DataFieldSettingsDelegate extends WatchUi.BehaviorDelegate {
  //! Constructor
  function initialize() {
    BehaviorDelegate.initialize();
  }

  //! Handle the menu event
  //! @return true if handled, false otherwise
  function onMenu() as Boolean {
    var menu = new $.DataFieldSettingsMenu();
    var mi = new WatchUi.MenuItem("Hiit", "High-Intensity Interval", "hiit", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Targets", null, "targets", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Power", null, "power", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Gradient", null, "gradient", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Show pressure", null, "pressure", null);
    menu.addItem(mi);

    mi = new WatchUi.MenuItem("Large field", null, "large_field", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Wide field", null, "wide_field", null);
    menu.addItem(mi);
    mi = new WatchUi.MenuItem("Small field", null, "small_field", null);
    menu.addItem(mi);


    var boolean = false;

    boolean = Storage.getValue("show_colors") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Colors", null, "show_colors", boolean, null));

    boolean = Storage.getValue("show_grid") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Grid lines", null, "show_grid", boolean, null));

    mi = new WatchUi.MenuItem("Timer", null, "show_timer", null);
    var value = getStorageValue(mi.getId() as String, $.gShowTimer) as Number;
    mi.setSubLabel($.getShowTimerText(value));
    menu.addItem(mi);

    // boolean = Storage.getValue("show_timer") ? true : false;
    // mi = new WatchUi.ToggleMenuItem("Timer", null, "show_timer", boolean, null);
    // mi.setSubLabel($.subMenuToggleMenuItem(mi.getId() as String));
    // menu.addItem(mi);

    // @@QND
    // boolean = Storage.getValue("wf_toggle_heading") ? true : false;
    // mi = new WatchUi.ToggleMenuItem("Field 2 (small)", null, "wf_toggle_heading", boolean, null);
    // mi.setSubLabel($.subMenuToggleMenuItem(mi.getId() as String));
    // menu.addItem(mi);
    //  gWideFieldShowDistance = getStorageValue("wf_toggle_heading", gWideFieldShowDistance) as Boolean;

    boolean = Storage.getValue("resetDefaults") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Reset to defaults", null, "resetDefaults", boolean, null));

    boolean = Storage.getValue("debug") ? true : false;
    menu.addItem(new WatchUi.ToggleMenuItem("Debug", null, "debug", boolean, null));

    var view = new $.DataFieldSettingsView();
    WatchUi.pushView(menu, new $.DataFieldSettingsMenuDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    return true;
  }

  function onBack() as Boolean {
    $.gExitedMenu = true;
    getApp().onSettingsChanged();
    return false;
  }
}

function subMenuToggleMenuItem(key as String) as String {
  // if (key.equals("show_timer")) {
  //   if (Storage.getValue(key) ? true : false) {
  //     return "timer time";
  //   } else {
  //     return "elapsed time";
  //   }
  // }
  // else if (key.equals("wf_toggle_heading")) {
  //   if (Storage.getValue(key) ? true : false) {
  //     return "distance (next)";
  //   } else {
  //     return "heading";
  //   }
  // }
  return "";
}
