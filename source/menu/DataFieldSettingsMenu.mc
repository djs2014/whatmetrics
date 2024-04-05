import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class DataFieldSettingsMenu extends WatchUi.Menu2 {
  function initialize() {
    Menu2.initialize({ :title => "Settings" });
  }
}

//! Handles menu input and stores the menu data
class DataFieldSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _currentMenuItem as MenuItem?;
  hidden var _view as DataFieldSettingsView;

  function initialize(view as DataFieldSettingsView) {
    Menu2InputDelegate.initialize();
    _view = view;
  }

  function onSelect(item as MenuItem) as Void {
    _currentMenuItem = item;
    var id = item.getId();

    if (id instanceof String && id.equals("hiit")) {
      var hiitMenu = new WatchUi.Menu2({ :title => "High-intensity interval" });

      var mi = new WatchUi.MenuItem("Mode", null, "hiit_mode", null);
      var value = getStorageValue(mi.getId() as String, WhatHiitt.HiitDisabled) as WhatHiitt.HiitMode;
      mi.setSubLabel($.getHiittModeText(value));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sound", null, "hiit_sound", null);
      value = getStorageValue(mi.getId() as String, WhatHiitt.NoSound) as WhatHiitt.HiitSound;
      mi.setSubLabel($.getHiittSoundText(value));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Start when % of target|0~500", null, "hiit_startperc", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Stop when % of target|0~500", null, "hiit_stopperc", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec countdown to start|0~30", null, "hiit_countdown", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec inactivity until stop|0~60", null, "hiit_inactivity", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec valid hiit", null, "hiit_valid_sec", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec recovery", null, "hiit_recovery_sec", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      WatchUi.pushView(hiitMenu, new $.GeneralMenuDelegate(self, hiitMenu), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("targets")) {
      var targetMenu = new WatchUi.Menu2({ :title => "Targets" });
      // "Functional threshold power"
      var mi = new WatchUi.MenuItem("FTP", null, "target_ftp", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Target speed km/h", null, "target_speed", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Target cadence rpm", null, "target_cadence", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Target calories kcal", null, "target_calories", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Target grade %", null, "target_grade", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Target altitude meters", null, "target_altitude", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Target heartrate zone", null, "target_hrzone", null);
      mi.setSubLabel("zone " + $.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      WatchUi.pushView(targetMenu, new $.GeneralMenuDelegate(self, targetMenu), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("gradient")) {
      var gradientMenu = new WatchUi.Menu2({ :title => "Gradient" });

      var mi = new WatchUi.MenuItem("Window size", null, "metric_gradews", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      gradientMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Minimal rise in cm", null, "metric_grademinrise", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      gradientMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Minimal run in cm", null, "metric_grademinrun", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      gradientMenu.addItem(mi);

      WatchUi.pushView(gradientMenu, new $.GeneralMenuDelegate(self, gradientMenu), WatchUi.SLIDE_LEFT);
      return;
    }
    if (id instanceof String && id.equals("power")) {
      var powerMenu = new WatchUi.Menu2({ :title => "Power metrics" });

      var mi = new WatchUi.MenuItem("Power per sec", null, "metric_ppersec", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      powerMenu.addItem(mi);

      var boolean = Storage.getValue("show_powerbalance") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("Power balance", null, "show_powerbalance", boolean, null));

      boolean = Storage.getValue("show_powerbattery") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("Power batt. level", null, "show_powerbattery", boolean, null));

      mi = new WatchUi.MenuItem("Sec. to fallback distance", null, "power_countdowntofallback", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      powerMenu.addItem(mi);

      boolean = Storage.getValue("show_powerbatterytime") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("Power batt. time", null, "show_powerbatterytime", boolean, null));

      mi = new WatchUi.MenuItem("Power battery max hour", null, "metric_pbattmaxhour", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      powerMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Power set remain hour", null, "metric_pbattsetremaininghour", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      powerMenu.addItem(mi);

      boolean = Storage.getValue("show_powerperweight") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("Power per weight", null, "show_powerperweight", boolean, null));

      boolean = Storage.getValue("show_poweraverage") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("Power average", null, "show_poweraverage", boolean, null));

      mi = new WatchUi.MenuItem("Dualpwr sec fallback", null, "power_dual_sec_fallback", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      powerMenu.addItem(mi);

      WatchUi.pushView(powerMenu, new $.GeneralMenuDelegate(self, powerMenu), WatchUi.SLIDE_LEFT);
      return;
    }
    if (id instanceof String && id.equals("pressure")) {
      var pressMenu = new WatchUi.Menu2({ :title => "Pressure or altitude" });

      var mi = new WatchUi.MenuItem("Min altitude", null, "pressure_altmin", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      pressMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Max altitude", null, "pressure_altmax", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      pressMenu.addItem(mi);

      var boolean = Storage.getValue("pressure_show_meansealevel") ? true : false;
      pressMenu.addItem(new WatchUi.ToggleMenuItem("Mean sealevel", null, "pressure_show_meansealevel", boolean, null));

      WatchUi.pushView(pressMenu, new $.GeneralMenuDelegate(self, pressMenu), WatchUi.SLIDE_LEFT);
      return;
    }

    if (id instanceof String && id.equals("show_timer")) {
      var sp = new selectionMenuPicker("Show time(r)", id as String);
      for (var i = 0; i <= 2; i++) {
        sp.add($.getShowTimerText(i), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    if (id instanceof String && item instanceof ToggleMenuItem) {
      Storage.setValue(id as String, item.isEnabled());
      item.setSubLabel($.subMenuToggleMenuItem(id as String));
      return;
    }
  }

  function onSelectedSelection(value as Object, storageKey as String) as Void {
    Storage.setValue(storageKey, value as Number);
  }
}

class GeneralMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _delegate as DataFieldSettingsMenuDelegate;
  hidden var _item as MenuItem?;
  hidden var _currentPrompt as String = "";
  hidden var _debug as Boolean = false;

  function initialize(delegate as DataFieldSettingsMenuDelegate, menu as WatchUi.Menu2) {
    Menu2InputDelegate.initialize();
    _delegate = delegate;
  }

  function onSelect(item as MenuItem) as Void {
    _item = item;
    var id = item.getId() as String;

    if (id instanceof String && item instanceof ToggleMenuItem) {
      Storage.setValue(id as String, item.isEnabled());
      item.setSubLabel($.subMenuToggleMenuItem(id as String));
      return;
    } else if (id instanceof String && id.equals("hiit_mode")) {
      var sp = new selectionMenuPicker("Hiit mode", id as String);
      sp.add("Disabled", "hiit is not active", WhatHiitt.HiitDisabled);
      sp.add("Minimal", "hiit minimized", WhatHiitt.HiitMinimal);
      sp.add("Normal", "hiit full screen", WhatHiitt.HiitNormal);

      //sp.setOnSelected(self, :onSelectedHiitMode, item);
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    } else if (id instanceof String && id.equals("hiit_sound")) {
      var sp = new selectionMenuPicker("Hiit sound", id as String);
      sp.add("No sound", null, WhatHiitt.NoSound);
      sp.add("Start only", null, WhatHiitt.StartOnlySound);
      sp.add("Low", "low noise", WhatHiitt.LowNoise);
      sp.add("Loud", "loud noise", WhatHiitt.LoudNoise);

      //sp.setOnSelected(self, :onSelectedHiitSound, item);
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    } else if (id.equals("target_hrzone")) {
      var sp = new selectionMenuPicker("Target heartrate zone", id as String);
      sp.add("Zone 1", null, 1);
      sp.add("Zone 2", null, 2);
      sp.add("Zone 3", null, 3);
      sp.add("Zone 4", null, 4);
      sp.add("Zone 5", null, 5);

      //sp.setOnSelected(self, :onSelectedHrZone, item);
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    _currentPrompt = item.getLabel();
    var numericOptions = parseLabelToOptions(_currentPrompt);

    var currentValue = $.getStorageValue(id as String, 0) as Numeric;
    if (numericOptions.isFloat) {
      currentValue = currentValue.toFloat();
    }
    var view = new $.NumericInputView(_debug, _currentPrompt, currentValue);
    view.processOptions(numericOptions);

    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_RIGHT);
  }

  function onAcceptNumericinput(value as Numeric) as Void {
    try {
      if (_item != null) {
        var storageKey = _item.getId() as String;
        Storage.setValue(storageKey, value);

        switch (value) {
          case instanceof Long:
          case instanceof Number:
            (_item as MenuItem).setSubLabel(value.format("%.0d"));
            break;
          case instanceof Float:
          case instanceof Double:
            (_item as MenuItem).setSubLabel(value.format("%.2f"));
            break;
        }
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function onNumericinput(
    editData as Array<Char>,
    cursorPos as Number,
    insert as Boolean,
    negative as Boolean,
    opt as NumericOptions
  ) as Void {
    // Hack to refresh screen
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    var view = new $.NumericInputView(_debug, _currentPrompt, 0);
    view.processOptions(opt);
    view.setEditData(editData, cursorPos, insert, negative);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_IMMEDIATE);
  }

  //! Handle the back key being pressed

  function onBack() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  //! Handle the done item being selected

  function onDone() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  // --

  function onSelectedSelection(value as Object, storageKey as String) as Void {
    Storage.setValue(storageKey, value as Number);
  }

  // function onSelectedHiitMode(value as Object, storageKey as String) as Void {
  //   var HiitMode = value as WhatHiitt.HiitMode;
  //   Storage.setValue(storageKey, HiitMode);
  //   if (_item != null) {
  //     (_item as MenuItem).setSubLabel($.getHiittModeText(HiitMode));
  //   }
  // }

  // function onSelectedHiitSound(value as Object, storageKey as String) as Void {
  //   var HiitSound = value as WhatHiitt.HiitSound;
  //   Storage.setValue(storageKey, HiitSound);
  //   if (_item != null) {
  //     (_item as MenuItem).setSubLabel($.getHiittSoundText(HiitSound));
  //   }
  // }

  // function onSelectedHrZone(value as Object, storageKey as String) as Void {
  //   var zone = value as Number;
  //   Storage.setValue(storageKey, zone);
  //   if (_item != null) {
  //     (_item as MenuItem).setSubLabel("zone " + zone.format("%0d"));
  //   }
  // }
}

// global

function getShowTimerText(value as Number) as String {
  switch (value) {
    case 0:
      return "timer";
    case 1:
      return "elapsed time";
    case 2:
      return "clock";

    default:
      return "--";
  }
}

function getHiittModeText(value as WhatHiitt.HiitMode) as String {
  switch (value) {
    case WhatHiitt.HiitMinimal:
      return "minimal";
    case WhatHiitt.HiitNormal:
      return "normal";
    default:
      return "disabled";
  }
}
function getHiittSoundText(value as WhatHiitt.HiitSound) as String {
  switch (value) {
    case WhatHiitt.StartOnlySound:
      return "start only";
    case WhatHiitt.LowNoise:
      return "low noise";
    case WhatHiitt.LoudNoise:
      return "loud noise";
    default:
      return "no sound";
  }
}

function getStorageNumberAsString(key as String) as String {
  return (getStorageValue(key, 0) as Number).format("%.0d");
}
