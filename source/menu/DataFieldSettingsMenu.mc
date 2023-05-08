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

  //! Constructor

  function initialize(view as DataFieldSettingsView) {
    Menu2InputDelegate.initialize();
    _view = view;
  }

  function onSelect(menuItem as MenuItem) as Void {
    _currentMenuItem = menuItem;
    var id = menuItem.getId();

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

      mi = new WatchUi.MenuItem("Start when % of target", null, "hiit_startperc", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Stop when % of target", null, "hiit_stopperc", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec countdown to start", null, "hiit_countdown", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec inactivity until stop", null, "hiit_inactivity", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec valid hiit", null, "hiit_valid_sec", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec recovery", null, "hiit_recovery_sec", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      hiitMenu.addItem(mi);

      WatchUi.pushView(hiitMenu, new $.HiittMenuDelegate(self, hiitMenu), WatchUi.SLIDE_UP);
    } else if (id instanceof String && id.equals("targets")) {
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

      mi = new WatchUi.MenuItem("Power per sec", null, "metric_ppersec", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Grade window size", null, "metric_gradews", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      WatchUi.pushView(targetMenu, new $.TargetsMenuDelegate(self, targetMenu), WatchUi.SLIDE_UP);
    } else if (id instanceof String && menuItem instanceof ToggleMenuItem) {
      Storage.setValue(id as String, menuItem.isEnabled());
      menuItem.setSubLabel($.subMenuToggleMenuItem(id as String));
    }
  }
}

class HiittMenuDelegate extends WatchUi.Menu2InputDelegate {
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
    var id = item.getId();
    if (id instanceof String && id.equals("hiit_mode")) {
      var sp = new selectionMenuPicker("Hiit mode", id as String);
      sp.add("Disabled", "hiit is not active", WhatHiitt.HiitDisabled);
      sp.add("Minimal", "hiit minimized", WhatHiitt.HiitMinimal);
      sp.add("Normal", "hiit full screen", WhatHiitt.HiitNormal);

      sp.setOnSelected(self, :onSelectedHiitMode);
      sp.show();
    } else if (id instanceof String && id.equals("hiit_sound")) {
      var sp = new selectionMenuPicker("Hiit sound", id as String);
      sp.add("No sound", null, WhatHiitt.NoSound);
      sp.add("Start only", null, WhatHiitt.StartOnlySound);
      sp.add("Low", "low noise", WhatHiitt.LowNoise);
      sp.add("Loud", "loud noise", WhatHiitt.LoudNoise);

      sp.setOnSelected(self, :onSelectedHiitSound);
      sp.show();
    } else {
      _currentPrompt = item.getLabel();

      var currentValue = $.getStorageValue(id as String, 0) as Number;
      var view = new $.NumericInputView(_debug, _currentPrompt, currentValue);

      view.setOnAccept(self, :onAcceptNumericinput);
      view.setOnKeypressed(self, :onNumericinput);

      Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_RIGHT);
    }
  }

  function onAcceptNumericinput(value as Number) as Void {
    try {
      if (_item != null) {
        var storageKey = _item.getId() as String;
        Storage.setValue(storageKey, value);
        (_item as MenuItem).setSubLabel(value.format("%.0d"));
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function onNumericinput(editData as Array<Char>, cursorPos as Number, insert as Boolean) as Void {
    // Hack to refresh screen
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    var view = new $.NumericInputView(_debug, _currentPrompt, 0);
    view.setEditData(editData, cursorPos, insert);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_IMMEDIATE);
  }

  function onSelectedHiitMode(value as Object, storageKey as String) as Void {
    var HiitMode = value as WhatHiitt.HiitMode;
    Storage.setValue(storageKey, HiitMode);
    if (_item != null) {
      (_item as MenuItem).setSubLabel($.getHiittModeText(HiitMode));
    }
  }

  function onSelectedHiitSound(value as Object, storageKey as String) as Void {
    var HiitSound = value as WhatHiitt.HiitSound;
    Storage.setValue(storageKey, HiitSound);
    if (_item != null) {
      (_item as MenuItem).setSubLabel($.getHiittSoundText(HiitSound));
    }
  }

  //! Handle the back key being pressed

  function onBack() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  //! Handle the done item being selected

  function onDone() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }
}

class TargetsMenuDelegate extends WatchUi.Menu2InputDelegate {
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

    if (id.equals("target_hrzone")) {
      var sp = new selectionMenuPicker("Target heartrate zone", id as String);
      sp.add("Zone 1", null, 1);
      sp.add("Zone 2", null, 2);
      sp.add("Zone 3", null, 3);
      sp.add("Zone 4", null, 4);
      sp.add("Zone 5", null, 5);

      sp.setOnSelected(self, :onSelectedHrZone);
      sp.show();
      return;
    }

    _currentPrompt = item.getLabel();

    var currentValue = $.getStorageValue(id as String, 0) as Number;
    var view = new $.NumericInputView(_debug, _currentPrompt, currentValue);

    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_RIGHT);
  }

  function onSelectedHrZone(value as Object, storageKey as String) as Void {
    var zone = value as Number;
    Storage.setValue(storageKey, zone);
    if (_item != null) {
      (_item as MenuItem).setSubLabel("zone " + zone.format("%0d"));
    }
  }

  function onAcceptNumericinput(value as Number) as Void {
    try {
      if (_item != null) {
        var storageKey = _item.getId() as String;
        Storage.setValue(storageKey, value);
        (_item as MenuItem).setSubLabel(value.format("%.0d"));
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function onNumericinput(editData as Array<Char>, cursorPos as Number, insert as Boolean) as Void {
    // Hack to refresh screen
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    var view = new $.NumericInputView(_debug, _currentPrompt, 0);
    view.setEditData(editData, cursorPos, insert);
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
}

// global
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
