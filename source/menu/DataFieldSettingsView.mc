import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

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

    var boolean = Storage.getValue("debug") ? true : false;
    menu.addItem(
      new WatchUi.ToggleMenuItem(
        "Debug",
        null,
        "debug",
        boolean,
        null
      )
    );
    
    boolean = Storage.getValue("show_colors") ? true : false;
    menu.addItem(
      new WatchUi.ToggleMenuItem(
        "Show colors",
        null,
        "show_colors",
        boolean,
        null
      )
    );

    var view = new $.DataFieldSettingsView();
    WatchUi.pushView(
      menu,
      new $.DataFieldSettingsMenuDelegate(view),
      WatchUi.SLIDE_IMMEDIATE
    );
    return true;
  }

   function onBack() as Boolean {
    getApp().onSettingsChanged();
    return false;
  }
}