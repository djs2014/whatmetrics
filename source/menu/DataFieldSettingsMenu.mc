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

      boolean = Storage.getValue("power_times_two") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("Power*2 (pedal fail)", null, "power_times_two", boolean, null));

      WatchUi.pushView(powerMenu, new $.GeneralMenuDelegate(self, powerMenu), WatchUi.SLIDE_LEFT);
      return;
    }
   
    if (id instanceof String && (id.equals("large_field") || id.equals("wide_field") || id.equals("small_field"))) {
      var label = item.getLabel();
      var prefix = id.toString();
      var fieldMenu = new WatchUi.Menu2({ :title => label + " items" });
      for (var i = 0; i < 8; i++) {
        var mi = new WatchUi.MenuItem("Field " + (i + 1), null, prefix + "|" + i.format("%d"), null);
        mi.setSubLabel($.getFieldByIndex(prefix, i));
        fieldMenu.addItem(mi);
      }

      // Zenmode
      var idzen = prefix + "_zen";
      var mi = new WatchUi.MenuItem("Zen mode", null, idzen, null);
      var zm = $.getStorageValue(idzen, ZMOff) as ZenMode;
      mi.setSubLabel($.getZenModeAsString(zm));
      fieldMenu.addItem(mi);

      WatchUi.pushView(fieldMenu, new $.GeneralMenuDelegate(self, fieldMenu), WatchUi.SLIDE_UP);
      return;
    }

    if (id instanceof String && id.equals("fallbacks")) {
      var fbMenu = new WatchUi.Menu2({ :title => "Fallback for field" });

      var mi = new WatchUi.MenuItem("Power", null, "fb_power", null);
      var value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Power per weight", null, "fb_power_per_weight", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Power balance", null, "fb_power_balance", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Heartrate", null, "fb_heart_rate", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Heartrate zone", null, "fb_heart_rate_zone", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Distance next", null, "fb_distance_next", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Distance dest", null, "fb_distance_dest", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Hiit", null, "fb_hiit", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Altitude", null, "fb_altitude", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Grade", null, "fb_grade", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Cadence", null, "fb_cadence", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Gear combo", null, "fb_gear_combo", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Gear index", null, "fb_gear_index", null);
      value = $.getStorageValue(mi.getId() as String, FTUnknown) as FieldType;
      mi.setSubLabel($.getFieldIdAsString(value));
      fbMenu.addItem(mi);

      WatchUi.pushView(fbMenu, new $.GeneralMenuDelegate(self, fbMenu), WatchUi.SLIDE_UP);
      return;
    }

    if (id instanceof String && id.equals("fallbackstriggers")) {
      var fbtMenu = new WatchUi.Menu2({ :title => "Fallback triggers" });

      var mi = new WatchUi.MenuItem("Sec. 0 power", null, "power_countdowntofallback", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      fbtMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Sec. 0 cadence", null, "cadence_countdowntofallback", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      fbtMenu.addItem(mi);

      // !! fb_ in key already used
      mi = new WatchUi.MenuItem("Altitude start", null, "altitude_start_fb", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      fbtMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Altitude end", null, "altitude_end_fb", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      fbtMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Grade start", null, "grade_start_fb", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      fbtMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Grade end", null, "grade_end_fb", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      fbtMenu.addItem(mi);

      WatchUi.pushView(fbtMenu, new $.GeneralMenuDelegate(self, fbtMenu), WatchUi.SLIDE_UP);
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
    }
    if (id instanceof String && id.equals("hiit_mode")) {
      var sp = new selectionMenuPicker("Hiit mode", id as String);
      sp.add("Disabled", "hiit is not active", WhatHiitt.HiitDisabled);
      sp.add("Minimal", "hiit minimized", WhatHiitt.HiitMinimal);
      sp.add("Normal", "hiit full screen", WhatHiitt.HiitNormal);

      //sp.setOnSelected(self, :onSelectedHiitMode, item);
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("hiit_sound")) {
      var sp = new selectionMenuPicker("Hiit sound", id as String);
      sp.add("No sound", null, WhatHiitt.NoSound);
      sp.add("Start only", null, WhatHiitt.StartOnlySound);
      sp.add("Low", "low noise", WhatHiitt.LowNoise);
      sp.add("Loud", "loud noise", WhatHiitt.LoudNoise);

      //sp.setOnSelected(self, :onSelectedHiitSound, item);
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id.equals("target_hrzone")) {
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

    if (id.equals("large_field_zen") || id.equals("wide_field_zen") || id.equals("small_field_zen")) {
      var sp = new selectionMenuPicker("Zen mode", id as String);
      sp.add("Off", null, ZMOff);
      sp.add("On", null, ZMOn);
      sp.add("When moving", null, ZMWhenMoving);

      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    // Fields: key starts with large_field|, wide_field|, small_field|
    if (id.find("|") != null) {
      var prefix = stringLeft(id, "|", "");
      var index = stringRight(id, "|", "").toNumber();
      if (prefix == "" || index == null) {
        return;
      }
      var idx = index as Number;
      var sp = new selectionMenuPicker("Field " + (idx + 1), id as String);
      for (var i = 0; i < $.FieldTypeCount; i++) {
        sp.add($.getFieldIdAsString(i as FieldType), null, i);
      }
      sp.setOnSelected(self, :onSelectedField, item);
      sp.show();
      return;
    }

    // Fallback fields
    if (id.find("fb_") != null) {
      var sp = new selectionMenuPicker("Fallback for " + item.getLabel(), id as String);
      for (var i = 0; i < $.FieldTypeCount; i++) {
        sp.add($.getFieldIdAsString(i as FieldType), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    _currentPrompt = item.getLabel();
    var numericOptions = $.parseLabelToOptions(_currentPrompt);

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
  function onSelectedField(value as Object, storageKey as String) as Void {
    // storageKey large_field|0  (key and field index) value = 1 (field type)
    var key = stringLeft(storageKey, "|", "");
    var index = stringRight(storageKey, "|", "").toNumber();
    if (key == "" || index == null) {
      return;
    }
    var idx = index as Number;
    var fields = getStorageValue(key, [0, 0, 0, 0, 0, 0, 0, 0]) as Array<Number>;
    fields[idx] = value as Number;
    Storage.setValue(key, fields);
  }
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

function getFieldByIndex(key as String, index as Number) as String {
  var fields = getStorageValue(key, [0, 0, 0, 0, 0, 0, 0, 0]) as Array<Number>;
  if (index < 0 || index >= fields.size()) {
    return "--";
  }
  var field = fields[index] as FieldType;
  return $.getFieldIdAsString(field);
}

function getZenModeAsString(zenMode as ZenMode) as String {
  switch (zenMode) {
    case ZMOff:
      return "off";
    case ZMOn:
      return "on";
    case ZMWhenMoving:
      return "when moving";
    default:
      return "--";
  }
}

function getFieldIdAsString(fieldType as FieldType) as String {
  switch (fieldType) {
    case FTUnknown:
      return "unknown";
    case FTDistance:
      return "distance";
    case FTDistanceNext:
      return "distance next";
    case FTDistanceDest:
      return "distance dest";
    case FTGrade:
      return "grade";
    case FTClock:
      return "clock";
    case FTHeartRate:
      return "heartrate";
    case FTPower:
      return "power";
    case FTBearing:
      return "bearing";
    case FTSpeed:
      return "speed";
    case FTAltitude:
      return "altitude";
    case FTPressureAtSea:
      return "pressure at sea";
    case FTPressure:
      return "pressure";
    case FTCadence:
      return "cadence";
    case FTHiit:
      return "hiit";
    case FTTimer:
      return "timer";
    case FTTimeElapsed:
      return "time elapsed";
    case FTGearCombo:
      return "gear combo";
    case FTPowerPerWeight:
      return "power per weight";
    case FTPowerBalance:
      return "power balance";
    case FTHeartRateZone:
      return "heartrate zone";
    case FTGearIndex:
      return "gear index";
    default:
      return "unknown";
  }
}

function getStorageNumberAsString(key as String) as String {
  return (getStorageValue(key, 0) as Number).format("%.0d");
}
