import Toybox.Application;
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

      mi = new WatchUi.MenuItem("Start when % of target|0~500 (%)", null, "hiit_startperc", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " %");
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Stop when % of target|0~500 (%)", null, "hiit_stopperc", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " %");
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec countdown to start|0~30 (sec)", null, "hiit_countdown", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " sec");
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec inactivity until stop|0~60 (sec)", null, "hiit_inactivity", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " sec");
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec valid hiit| (sec)", null, "hiit_valid_sec", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " sec");
      hiitMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Sec recovery| (sec)", null, "hiit_recovery_sec", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " sec");
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
      mi = new WatchUi.MenuItem("Target IF|0.0~1.2", null, "target_if", null);
      mi.setSubLabel($.getStorageFloatAsString(mi.getId() as String));
      targetMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Target TSS|0~600", null, "target_tss", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Target heartrate zone", null, "target_hrzone", null);
      mi.setSubLabel("zone " + $.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Target distance km", null, "target_distance", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      var boolean = Storage.getValue("target_distance_route") ? true : false;
      targetMenu.addItem(new WatchUi.ToggleMenuItem("Route as distance", null, "target_distance_route", boolean, null));

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

      var boolean;
      //  boolean = Storage.getValue("show_powerbalance") ? true : false;
      // powerMenu.addItem(new WatchUi.ToggleMenuItem("Balance", null, "show_powerbalance", boolean, null));

      boolean = Storage.getValue("show_powerbattery") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("Batt. level", null, "show_powerbattery", boolean, null));

      boolean = Storage.getValue("show_np_as_avg") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("NP for avg", null, "show_np_as_avg", boolean, null));

      boolean = Storage.getValue("np_skip_zero") ? true : false;
      powerMenu.addItem(new WatchUi.ToggleMenuItem("NP skip zeros", null, "np_skip_zero", boolean, null));

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

      // Layout
      var mi = new WatchUi.MenuItem("Layout", null, prefix + "|0", null);
      mi.setSubLabel($.getLayoutByIndex(prefix, 0));
      fieldMenu.addItem(mi);
      // Fields
      for (var i = 1; i < 9; i++) {
        mi = new WatchUi.MenuItem("Field " + i, null, prefix + "|" + i.format("%d"), null);
        mi.setSubLabel($.getFieldByIndex(prefix, i));
        fieldMenu.addItem(mi);
      }
      // Zenmode
      var idzen = prefix + "_zen";
      mi = new WatchUi.MenuItem("Zen mode", null, idzen, null);
      var zm = $.getStorageValue(idzen, ZMOff) as ZenMode;
      mi.setSubLabel($.getZenModeAsString(zm));
      fieldMenu.addItem(mi);

      // Bar position
      var idbar = prefix + "_bp";
      mi = new WatchUi.MenuItem("Bar position", null, idbar, null);
      var bp = $.getStorageValue(idbar, BPOff) as BarPosition;
      mi.setSubLabel($.getBarPositionAsString(bp));
      fieldMenu.addItem(mi);

      WatchUi.pushView(fieldMenu, new $.GeneralMenuDelegate(self, fieldMenu), WatchUi.SLIDE_UP);
      return;
    }

    // @@ TODO show large / wide / small
    if (id instanceof String && id.equals("graphic_fields")) {
      var label = item.getLabel();
      var prefix = "graphic_fields";
      var gfieldMenu = new WatchUi.Menu2({ :title => label + " items" });

      var boolean = Storage.getValue("show_graphic_fields") ? true : false;
      gfieldMenu.addItem(new WatchUi.ToggleMenuItem("Visible", null, "show_graphic_fields", boolean, null));

      var mi = new WatchUi.MenuItem("Line width|1~10", null, "gf_line_width", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      gfieldMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Zones|0~12", null, "gf_zones", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      gfieldMenu.addItem(mi);
      // Fields
      for (var i = 0; i < 5; i++) {
        mi = new WatchUi.MenuItem("Field " + i, null, prefix + "|" + i.format("%d"), null);
        mi.setSubLabel($.getFieldByIndex(prefix, i));
        gfieldMenu.addItem(mi);
      }

      WatchUi.pushView(gfieldMenu, new $.GeneralMenuDelegate(self, gfieldMenu), WatchUi.SLIDE_UP);
      return;
    }

    if (id instanceof String && id.equals("demofieldsmenu")) {
      var demMenu = new WatchUi.Menu2({ :title => "Cycle through fields" });

      var boolean = Storage.getValue("demofields") ? true : false;
      demMenu.addItem(new WatchUi.ToggleMenuItem("Show demo", null, "demofields", boolean, null));

      var mi = new WatchUi.MenuItem("Wait seconds|0~60 (sec)", null, "demofields_wait", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " sec");
      demMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Roundtrips|0~60 (sec)", null, "demofields_roundtrip", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String) + " sec");
      demMenu.addItem(mi);

      WatchUi.pushView(demMenu, new $.GeneralMenuDelegate(self, demMenu), WatchUi.SLIDE_UP);
      return;
    }
    if (id instanceof String && id.equals("fallbacks")) {
      var fbMenu = new WatchUi.Menu2({ :title => "Fallback for field" });

      // Fields, skip 0 (field Unknown)
      for (var i = 1; i < $.FieldTypeCount; i++) {
        if ($.fieldHasFallback(i)) {
          var field = i as FieldType;
          var mi = new WatchUi.MenuItem($.getFieldTypeAsString(field), null, "fields_fallback|" + i.format("%d"), null);
          mi.setSubLabel($.getFieldByIndex("fields_fallback", i));
          fbMenu.addItem(mi);
        }
      }      

      WatchUi.pushView(fbMenu, new $.GeneralMenuDelegate(self, fbMenu), WatchUi.SLIDE_UP);
      return;
    }

    if (id instanceof String && id.equals("fallbackstriggers")) {
      var fbtMenu = new WatchUi.Menu2({ :title => "Fallback triggers" });

      var mi = new WatchUi.MenuItem("Sec. 0 power", null, "power_countdowntofb", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      fbtMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Sec. 0 cadence", null, "cadence_countdowntofb", null);
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

    if (id instanceof String && id.equals("advancedmenu")) {
      var avMenu = new WatchUi.Menu2({ :title => "Advanced items" });

      var mi = new WatchUi.MenuItem("Pause x offset|0~30", null, "pause_x_offset", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      avMenu.addItem(mi);

      WatchUi.pushView(avMenu, new $.GeneralMenuDelegate(self, avMenu), WatchUi.SLIDE_UP);
      return;
    }

    if (id instanceof String && item instanceof ToggleMenuItem) {
      Storage.setValue(id as String, item.isEnabled());
      item.setSubLabel($.subMenuToggleMenuItem(id as String));
      return;
    }
  }

  function onSelectedSelection(storageKey as String, value as Application.PropertyValueType) as Void {
    Storage.setValue(storageKey, value);
  }
}

class GeneralMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _delegate as DataFieldSettingsMenuDelegate;
  hidden var _item as MenuItem?;
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
      var sp = new selectionMenuPicker("Hiit mode, visible", id as String);
      for(var i = 0; i < 3; i++) {
        sp.add($.getHiittModeText(i as WhatHiitt.HiitMode), null, i);
      }
      // sp.add("Disabled", "hiit is not active", WhatHiitt.HiitDisabled);
      // sp.add("Minimal", "hiit minimized", WhatHiitt.HiitWhenActive);
      // sp.add("Normal", "hiit full screen", WhatHiitt.HiitAlwaysOn);

      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }
    if (id instanceof String && id.equals("hiit_sound")) {
      var sp = new selectionMenuPicker("Hiit sound", id as String);
      for(var i = 0; i < 4; i++) {
        sp.add($.getHiittSoundText(i as WhatHiitt.HiitSound), null, i);
      }
      // sp.add("No sound", null, WhatHiitt.NoSound);
      // sp.add("Start only", null, WhatHiitt.StartOnlySound);
      // sp.add("Low", "low noise", WhatHiitt.LowNoise);
      // sp.add("Loud", "loud noise", WhatHiitt.LoudNoise);

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

      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    if (id.equals("large_field_zen") || id.equals("wide_field_zen") || id.equals("small_field_zen")) {
      var sp = new selectionMenuPicker("Zen mode", id as String);
      for(var i = 0; i < 3; i++) {
        sp.add($.getZenModeAsString(i as ZenMode), null, i);
      }
      
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    if (id.equals("large_field_bp") || id.equals("wide_field_bp") || id.equals("small_field_bp")) {
      var sp = new selectionMenuPicker("Bar position", id as String);
      for(var i = 0; i < 3; i++) {
        sp.add($.getBarPositionAsString(i as BarPosition), null, i);
      }
      
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    // Fallback fields, storage in fields_fallback
    if (id.find("fields_fallback|") != null) {
      var prefix = stringLeft(id, "|", "");
      var index = stringRight(id, "|", "").toNumber();
      if (prefix == "" || index == null) {
        return;
      }
      var idx = index as Number;
      var label = "Set fallback: " + $.getFieldTypeAsString(idx as FieldType);
      var sp = new selectionMenuPicker(label, id as String);
      for (var i = 0; i < $.FieldTypeCount; i++) {
        sp.add($.getFieldTypeAsString(i as FieldType), null, i);
      }
      sp.setOnSelected(self, :onSelectedFieldFallback, item);
      sp.show();
      return;
    }

    // Graphic fields, storage in graphic_fields
    if (id.find("graphic_fields|") != null) {
      var prefix = stringLeft(id, "|", "");
      var index = stringRight(id, "|", "").toNumber();
      if (prefix == "" || index == null) {
        return;
      }
      var idx = index as Number;
      var label = "Line: " + $.getFieldTypeAsString(idx as FieldType);
      var sp = new selectionMenuPicker(label, id as String);
      for (var i = 0; i < $.FieldTypeCount; i++) {
        if ($.fieldHasGraphic(i)) {
          sp.add($.getFieldTypeAsString(i as FieldType), null, i);
        }
      }
      sp.setOnSelected(self, :onSelectedField, item);
      sp.show();
      return;
    }

    if (id.find("|") != null) {
      var prefix = stringLeft(id, "|", "");
      var index = stringRight(id, "|", "").toNumber();
      if (prefix == "" || index == null) {
        return;
      }
      var idx = index as Number;
      if (idx == 0) {
        var sp = new selectionMenuPicker("Field layout", id as String);
        for (var i = 0; i < $.FieldLayoutCount; i++) {
          sp.add($.getFieldLayoutAsString(i as FieldLayout), null, i);
        }
        sp.setOnSelected(self, :onSelectedField, item);
        sp.show();
        return;
      }

      var sp = new selectionMenuPicker("Field " + idx, id as String);
      for (var i = 0; i < $.FieldTypeCount; i++) {
        sp.add($.getFieldTypeAsString(i as FieldType), null, i);
      }
      sp.setOnSelected(self, :onSelectedField, item);
      sp.show();
      return;
    }

    // Fallback fields
    if (id.find("fb_") != null) {
      var sp = new selectionMenuPicker("Fallback for " + item.getLabel(), id as String);
      for (var i = 0; i < $.FieldTypeCount; i++) {
        sp.add($.getFieldTypeAsString(i as FieldType), null, i);
      }
      sp.setOnSelected(self, :onSelectedSelection, item);
      sp.show();
      return;
    }

    // Numeric input
    var prompt = item.getLabel();
    var value = $.getStorageValue(id as String, 0) as Numeric;
    var view = $.getNumericInputView(prompt, value);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(view, new $.NumericInputDelegate(_debug, view), WatchUi.SLIDE_RIGHT);
  }

  function onAcceptNumericinput(value as Numeric, subLabel as String) as Void {
    try {
      if (_item != null) {
        var storageKey = _item.getId() as String;

        Storage.setValue(storageKey, value);
        (_item as MenuItem).setSubLabel(subLabel);
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
    var view = new $.NumericInputView("", 0);
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

  function onSelectedSelection(storageKey as String, value as Application.PropertyValueType) as Void {
    Storage.setValue(storageKey, value);
  }

  function onSelectedFieldLayout(storageKey as String, value as Application.PropertyValueType) as Void {
    // storageKey large_field|0  (key and field index) value = 1 (field type)
    var key = stringLeft(storageKey, "|", "");
    var index = 0;
    if (key == "" || index == null) {
      return;
    }
    var idx = index as Number;
    var fields = getStorageValue(key, [0, 0, 0, 0, 0, 0, 0, 0, 0]) as Array<Number>;
    if (idx < fields.size()) {
      fields[idx] = value as Number;
      Storage.setValue(key, fields as Lang.Array<Application.PropertyValueType>);
    }
  }

  function onSelectedField(storageKey as String, value as Application.PropertyValueType) as Void {
    // storageKey large_field|0  (key and field index) value = 1 (field type)
    var key = stringLeft(storageKey, "|", "");
    var index = stringRight(storageKey, "|", "").toNumber();
    if (key == "" || index == null) {
      return;
    }
    var idx = index as Number;
    var fields = getStorageValue(key, [0, 0, 0, 0, 0, 0, 0, 0, 0]) as Array<Number>;
    if (idx < fields.size()) {
      fields[idx] = value as Number;
      Storage.setValue(key, fields as Lang.Array<Application.PropertyValueType>);
    }
  }

  function onSelectedFieldFallback(storageKey as String, value as Application.PropertyValueType) as Void {
    // storageKey large_field|0  (key and field index) value = 1 (field type)
    var key = stringLeft(storageKey, "|", "");
    var index = stringRight(storageKey, "|", "").toNumber();
    if (key == "" || index == null) {
      return;
    }
    var idx = index as Number;
   
    var fields = getStorageValue(key, [0, 0, 0, 0, 0, 0, 0, 0, 0]) as Array<Number>;
    // Array can get bigger
    while (fields.size() < $.FieldTypeCount) {
      fields.add(FTUnknown);
    }
    if (idx < fields.size()) {
      fields[idx] = value as Number;
      Storage.setValue(key, fields as Lang.Array<Application.PropertyValueType>);
    }
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
    case WhatHiitt.HiitWhenActive:
      return "when active";
    case WhatHiitt.HiitAlwaysOn:
      return "always on";
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

// Content array: [layout, field 1 .. field 8 ]
function getLayoutByIndex(key as String, index as Number) as String {
  var fields = getStorageValue(key, []) as Array<Number>;
  if (index < 0 || index >= fields.size()) {
    return "--";
  }
  return $.getFieldLayoutAsString(fields[index] as FieldLayout);
}

// Content array: [layout, field 1 .. field 8 ]
function getFieldByIndex(key as String, index as Number) as String {
  var fields = getStorageValue(key, []) as Array<Number>;
  if (index < 0 || index >= fields.size()) {
    return "--";
  }

  var field = fields[index] as FieldType;
  return $.getFieldTypeAsString(field);
}

function getGraphicInfoByIndex(key as String, index as Number) as String or Boolean {
  var fields = getStorageValue(key, []) as Array<Number>;
  if (index < 0 || index >= fields.size()) {
    return "--";
  }
  if (index == 0) {
    // Boolean: 0, 1, show line
    return fields[index] == 1;
  }
  if (index == 1) {
    // Number, width
    return fields[index].format("%0d");
  }
  var field = fields[index] as FieldType;
  return $.getFieldTypeAsString(field);
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

function getBarPositionAsString(barPosition as BarPosition) as String {
  switch (barPosition) {
    case BPOff:
      return "off";
    case BPTop:
      return "top";
    case BPBottom:
      return "bottom";
    default:
      return "off";
  }
}

function getFieldLayoutAsString(fieldLayout as FieldLayout) as String {
  switch (fieldLayout) {
    case FL8Fields:
      return "8 fields";
    case FL6Fields:
      return "6 fields";
    case FL4Fields:
      return "4 fields";
    default:
      return "unknown";
  }
}
function getFieldTypeAsString(fieldType as FieldType) as String {
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
    case FTAverageSpeed:
      return "avg speed";
    case FTAverageHeartRate:
      return "avg heartrate";
    case FTAveragePower:
      return "avg power";
    case FTAverageCadence:
      return "avg cadence";
    case FTNormalizedPower:
      return "normalized power";
    case FTIntensityFactor:
      return "intensity factor";
    case FTTrainingStressScore:
      return "training stress score";
    case FTCalories:
      return "calories";
    case FTEta:
      return "ET Arrival";
    case FTEtr:
      return "ET Remaining";
    default:
      return "unknown";
  }
}

function getStorageNumberAsString(key as String) as String {
  return (getStorageValue(key, 0) as Number).format("%0d");
}

function getStorageFloatAsString(key as String) as String {
  return (getStorageValue(key, 0) as Float).format("%.1f");
}

function fieldHasFallback(fieldId as Number) as Boolean {
  return (
    [
      FTDistanceNext,
      FTDistanceDest,
      FTGrade,
      FTHeartRate,
      FTPower,
      FTAltitude,
      FTCadence,
      FTGearCombo,
      FTPowerPerWeight,
      FTPowerBalance,
      FTHeartRateZone,
      FTGearIndex,
      FTAverageHeartRate,
      FTAveragePower,
      FTAverageCadence,
      FTNormalizedPower,
      FTIntensityFactor,
      FTTrainingStressScore,
      FTHiit,
      FTEta,
      FTEtr
    ].indexOf(fieldId) > -1
  );
}

function fieldHasGraphic(fieldId as Number) as Boolean {
  return (
    [
      FTUnknown,
      FTHeartRateZone,
      FTNormalizedPower,
      FTIntensityFactor,
      FTTrainingStressScore,
      FTSpeed,
      FTCadence,
      FTHeartRate,
      FTCalories,
      FTDistance
    ].indexOf(fieldId) > -1
  );
}
