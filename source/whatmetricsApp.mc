import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.UserProfile;

class whatmetricsApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {}

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {}

  //! Return the initial view of your application here
  function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
    onSettingsChanged();
    return [new whatmetricsView()];
  }

  //! Return the settings view and delegate for the app
  //! @return Array Pair [View, Delegate]
  function getSettingsView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null {
    return [new $.DataFieldSettingsView(), new $.DataFieldSettingsDelegate()];
  }
  function onSettingsChanged() {
    var hiitt = getHiitt();
    hiitt.updateProfile();

    var version = getStorageValue("version", "") as String;      
    if (!version.equals("1.0.0")) {
      Storage.setValue("version", "1.0.0");
      Storage.setValue("resetDefaults", true);
    }

    var reset = Storage.getValue("resetDefaults");
    if (reset == null || (reset as Boolean)) {
      Storage.setValue("resetDefaults", false);

      Storage.setValue("hiit_mode", WhatHiitt.HiitDisabled);
      Storage.setValue("hiit_sound", WhatHiitt.StartOnlySound);
      Storage.setValue("hiit_startperc", 150);
      Storage.setValue("hiit_stopperc", 100);
      Storage.setValue("hiit_countdown", 3);
      Storage.setValue("hiit_inactivity", 10);
      Storage.setValue("hiit_valid_sec", 30);
      Storage.setValue("hiit_recovery_sec", 300);

      Storage.setValue("target_ftp", gTargetFtp);
      Storage.setValue("target_speed", gTargetSpeed);
      Storage.setValue("target_cadence", gTargetCadence);
      Storage.setValue("target_calories", gTargetCalories);
      Storage.setValue("target_grade", gTargetGrade);
      Storage.setValue("target_altitude", gTargetAltitude);
      Storage.setValue("target_hrzone", 4);

      Storage.setValue("metric_ppersec", 3);
      Storage.setValue("metric_gradews", 4);
      Storage.setValue("metric_grademinrise", 0);
      Storage.setValue("metric_grademinrun", 20);

      Storage.setValue("debug", gDebug);
      Storage.setValue("show_colors", gShowColors);
      Storage.setValue("show_grid", gShowGrid);
      Storage.setValue("show_average", gShowAverageWhenPaused);
      Storage.setValue("show_powerbalance", gShowPowerBalance);
      Storage.setValue("show_powerbattery", gShowPowerBattery);
      Storage.setValue("show_powerbatterytime", gShowPowerBattTime);
      Storage.setValue("show_powerperweight", gShowPowerPerWeight);
      Storage.setValue("power_dual_sec_fallback", 0);
      Storage.setValue("power_times_two", false);

      Storage.setValue("metric_pbattmaxhour", gPowerBattMaxSeconds);

      Storage.setValue("altitude_start_fb", gAltitudeFallbackStart);
      Storage.setValue("altitude_end_fb", gAltitudeFallbackEnd);
      Storage.setValue("grade_start_fb", gGradeFallbackStart);
      Storage.setValue("grade_end_fb", gGradeFallbackEnd);

      $.gLargeField =
        [FTGrade, FTBearing, FTHeartRate, FTPower, FTSpeed, FTAltitude, FTCadence, FTHiit] as Array<Number>;
      $.gWideField =
        [FTGrade, FTDistanceNext, FTHeartRate, FTPower, FTSpeed, FTAltitude, FTCadence, FTHiit] as Array<Number>;
      $.gSmallField =
        [FTGrade, FTBearing, FTHeartRate, FTPower, FTSpeed, FTAltitude, FTCadence, FTHiit] as Array<Number>;
      Storage.setValue("large_field", $.gLargeField);
      Storage.setValue("wide_field", $.gWideField);
      Storage.setValue("small_field", $.gSmallField);

      Storage.setValue("large_field_zen", ZMWhenMoving);
      Storage.setValue("wide_field_zen", ZMWhenMoving);
      Storage.setValue("small_field_zen", ZMOn);

      Storage.setValue("fb_power", FTDistance);
      Storage.setValue("fb_power_per_weight", FTDistance);
      Storage.setValue("fb_power_balance", FTDistance);
      Storage.setValue("fb_heart_rate", FTTimer);
      Storage.setValue("fb_heart_rate_zone", FTTimeElapsed);
      Storage.setValue("fb_distance_next", FTDistanceDest);
      Storage.setValue("fb_distance_dest", FTDistance);
      Storage.setValue("fb_hiit", FTClock);
      Storage.setValue("fb_altitude", FTPressureAtSea);
      Storage.setValue("fb_grade", FTUnknown);
      Storage.setValue("fb_cadence", FTUnknown);
      Storage.setValue("fb_gear_combo", FTUnknown);
      Storage.setValue("fb_gear_index", FTUnknown);    
    }

    hiitt.setMode(getStorageValue("hiit_mode", WhatHiitt.HiitDisabled) as WhatHiitt.HiitMode);
    hiitt.setSound(getStorageValue("hiit_sound", WhatHiitt.StartOnlySound) as WhatHiitt.HiitSound);
    hiitt.setStartOnPerc(getStorageValue("hiit_startperc", 0) as Number);
    hiitt.setStopOnPerc(getStorageValue("hiit_stopperc", 0) as Number);
    var percs = hiitt.checkPerc();
    if (percs.size() == 2) {
      Storage.setValue("hiit_startperc", percs[0]);
      Storage.setValue("hiit_stopperc", percs[1]);  
    }
    hiitt.setStartCountDownSeconds(getStorageValue("hiit_countdown", 3) as Number);
    hiitt.setStopCountDownSeconds(getStorageValue("hiit_inactivity", 10) as Number);
    hiitt.setMinimalElapsedSeconds(getStorageValue("hiit_valid_sec", 30) as Number);
    hiitt.setMinimalRecoverySeconds(getStorageValue("hiit_recovery_sec", 300) as Number);

    var metrics = $.getWhatMetrics();
    metrics.setPowerPerSec(getStorageValue("metric_ppersec", 0) as Number);
    metrics.setGradeWindowSize(getStorageValue("metric_gradews", 0) as Number);
    metrics.setGradeMinimalRise(getStorageValue("metric_grademinrise", 0) as Number);
    metrics.setGradeMinimalRun(getStorageValue("metric_grademinrun", 20) as Number);

    gTargetFtp = getStorageValue("target_ftp", 0) as Number;
    gTargetSpeed = getStorageValue("target_speed", 0) as Number;
    gTargetCadence = getStorageValue("target_cadence", 0) as Number;
    gTargetCalories = getStorageValue("target_calories", 0) as Number;
    gTargetGrade = getStorageValue("target_grade", 0) as Number;
    gTargetAltitude = getStorageValue("target_altitude", 0) as Number;
    var targetHrZone = getStorageValue("target_hrzone", 4) as Number;

    var heartRateZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
    if (heartRateZones.size() > 0) {
      if (targetHrZone > 0 and targetHrZone < heartRateZones.size()) {
        gTargetHeartRate = (heartRateZones[targetHrZone - 1] + heartRateZones[targetHrZone]) / 2;
      } else {
        gTargetHeartRate = heartRateZones[heartRateZones.size() - 1];
      }
      metrics.initHrZones(heartRateZones);
    }

    $.gLargeField = getStorageValue("large_field", $.gLargeField) as Array<Number>;
    $.gWideField = getStorageValue("wide_field", $.gWideField) as Array<Number>;
    $.gSmallField = getStorageValue("small_field", $.gSmallField) as Array<Number>;

    $.gLargeFieldZen = getStorageValue("large_field_zen", $.gLargeFieldZen) as ZenMode;
    $.gWideFieldZen = getStorageValue("wide_field_zen", $.gWideFieldZen) as ZenMode;
    $.gSmallFieldZen = getStorageValue("small_field_zen", $.gSmallFieldZen) as ZenMode;

    $.gFBPower = getStorageValue("fb_power", $.gFBPower) as FieldType;
    $.gFBPowerPerWeight = getStorageValue("fb_power_per_weight", $.gFBPowerPerWeight) as FieldType;
    $.gFBPowerBalance = getStorageValue("fb_power_balance", $.gFBPowerBalance) as FieldType;
    $.gFBHeartRate = getStorageValue("fb_heart_rate", $.gFBHeartRate) as FieldType;
    $.gFBHeartRateZone = getStorageValue("fb_heart_rate_zone", $.gFBHeartRateZone) as FieldType;
    $.gFBDistanceNext = getStorageValue("fb_distance_next", $.gFBDistanceNext) as FieldType;
    $.gFBDistanceDest = getStorageValue("fb_distance_dest", $.gFBDistanceDest) as FieldType;
    $.gFBHiit = getStorageValue("fb_hiit", $.gFBHiit) as FieldType;
    $.gFBAltitude = getStorageValue("fb_altitude", $.gFBAltitude) as FieldType;
    $.gFBGrade = getStorageValue("fb_grade", $.gFBGrade) as FieldType;
    $.gFBCadence = getStorageValue("fb_cadence", $.gFBCadence) as FieldType;
    $.gFBGearCombo = getStorageValue("fb_gear_combo", $.gFBGearCombo) as FieldType;
    $.gFBGearIndex = getStorageValue("fb_gear_index", $.gFBGearIndex) as FieldType;

    gDebug = getStorageValue("debug", gDebug) as Boolean;
    gShowColors = getStorageValue("show_colors", gShowColors) as Boolean;
    gShowGrid = getStorageValue("show_grid", gShowGrid) as Boolean;
    gShowAverageWhenPaused = getStorageValue("show_average", gShowAverageWhenPaused) as Boolean;

    gAltitudeFallbackStart = getStorageValue("altitude_start_fb", 0) as Number;
    gAltitudeFallbackEnd = getStorageValue("altitude_end_fb", 0) as Number;
    gGradeFallbackStart = getStorageValue("grade_start_fb", 0) as Number;
    gGradeFallbackEnd = getStorageValue("grade_end_fb", 0) as Number;

    
    gShowPowerBalance = getStorageValue("show_powerbalance", gShowPowerBalance) as Boolean;
    gShowPowerBattery = getStorageValue("show_powerbattery", gShowPowerBattery) as Boolean;
    gShowPowerBattTime = getStorageValue("show_powerbatterytime", gShowPowerBattTime) as Boolean;
    gShowPowerPerWeight = getStorageValue("show_powerperweight", gShowPowerPerWeight) as Boolean;
    
    // @@ TODO
    var powerDualSecFallback = getStorageValue("power_dual_sec_fallback", 0) as Number;
    var powerTimesTwo = getStorageValue("power_times_two", false) as Boolean;
    $.gPowerCountdownToFallBack = getStorageValue("power_countdowntofallback", gPowerCountdownToFallBack) as Number;
    $.gCadenceCountdownToFallBack = getStorageValue("cadence_countdowntofallback", gCadenceCountdownToFallBack) as Number;

    var hours = getStorageValue("metric_pbattmaxhour", gPowerBattMaxSeconds / 3600) as Number;
    if (hours > 0 and hours < 1000) {
      gPowerBattMaxSeconds = hours * 60 * 60;
    }
    gPowerBattOperTimeCharched = getStorageValue("metric_pbattopertimecharched", 0) as Number;
    gPowerBattFullyCharched = getStorageValue("metric_pbattfullycharched", gPowerBattFullyCharched) as Boolean;
    gPowerBattSetRemainingHour = getStorageValue("metric_pbattsetremaininghour", 0) as Number;

    if (gShowPowerBalance or gShowPowerBattery or powerDualSecFallback > 0) {
      metrics.initPowerBalance(powerDualSecFallback, powerTimesTwo);
    }
    metrics.initWeight();
  }
}

function getApp() as whatmetricsApp {
  return Application.getApp() as whatmetricsApp;
}

function getHiitt() as WhatHiitt {
  if (gHiitt == null) {
    $.gHiitt = new WhatHiitt();
  }
  return $.gHiitt as WhatHiitt;
}
function getWhatMetrics() as WhatMetrics {
  if (gMetrics == null) {
    $.gMetrics = new WhatMetrics();
  }
  return $.gMetrics as WhatMetrics;
}
var gHiitt as WhatHiitt?;
var gMetrics as WhatMetrics?;
var gTargetFtp as Number = 250;
var gTargetSpeed as Number = 30;
var gTargetCadence as Number = 90;
var gTargetCalories as Number = 2000;
var gTargetGrade as Number = 8;
var gTargetAltitude as Number = 1000;
var gTargetHeartRate as Number = 200;
var gDebug as Boolean = false;

var gShowColors as Boolean = false;
var gShowGrid as Boolean = true;
var gShowAverageWhenPaused as Boolean = false; 

// @@ refactor
var gShowPowerBalance as Boolean = true;
var gShowPowerBattery as Boolean = true;
var gShowPowerPerWeight as Boolean = false;

// @@ to figure out
var gShowPowerBattTime as Boolean = false;
var gPowerBattMaxSeconds as Number = 0;
var gPowerBattOperTimeCharched as Number = 0;
var gPowerBattFullyCharched as Boolean = false;
var gPowerBattSetRemainingHour as Number = 0;

var gPowerCountdownToFallBack as Number = 10;
var gCadenceCountdownToFallBack as Number = 10;

var gAltitudeFallbackStart as Number = -10;
var gAltitudeFallbackEnd as Number = 10;
var gGradeFallbackStart as Number = -2;
var gGradeFallbackEnd as Number = 2;

var gLargeField as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
var gWideField as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
var gSmallField as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;

var gLargeFieldZen as ZenMode = ZMOff;
var gWideFieldZen as ZenMode = ZMOff;
var gSmallFieldZen as ZenMode = ZMOff;

// @@ Refactor: Can be one array 
var gFBPower as FieldType = FTUnknown;
var gFBPowerPerWeight as FieldType = FTUnknown;
var gFBPowerBalance as FieldType = FTUnknown;
var gFBHeartRate as FieldType = FTUnknown;
var gFBHeartRateZone as FieldType = FTUnknown;
var gFBDistanceNext as FieldType = FTUnknown;
var gFBDistanceDest as FieldType = FTUnknown;
var gFBHiit as FieldType = FTUnknown;
var gFBAltitude as FieldType = FTUnknown;
var gFBGrade as FieldType = FTUnknown;
var gFBCadence as FieldType = FTUnknown;
var gFBGearCombo as FieldType = FTUnknown;
var gFBGearIndex as FieldType = FTUnknown;