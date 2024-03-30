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
  function getInitialView() as Array<Views or InputDelegates>? {
    onSettingsChanged();
    return [new whatmetricsView()] as Array<Views or InputDelegates>;
  }

  //! Return the settings view and delegate for the app
  //! @return Array Pair [View, Delegate]
  function getSettingsView() as Array<Views or InputDelegates>? {
    return [new $.DataFieldSettingsView(), new $.DataFieldSettingsDelegate()] as Array<Views or InputDelegates>;
  }
  function onSettingsChanged() {
    var hiitt = getHiitt();
    hiitt.updateProfile();
    if (Storage.getValue("hiit_mode") == null) {
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
      Storage.setValue("show_timer", gShowTimer);
      Storage.setValue("show_powerbalance", gShowPowerBalance);
      Storage.setValue("show_powerbattery", gShowPowerBattery);
      Storage.setValue("show_powerbatterytime", gShowPowerBattTime);
      Storage.setValue("show_powerperweight", gShowPowerPerWeight);
      Storage.setValue("show_poweraverage", gShowPowerAverage);

      Storage.setValue("metric_pbattmaxhour", gPowerBattMaxSeconds);

      Storage.setValue("pressure_altmin", gHideAltitudeMin);
      Storage.setValue("pressure_altmax", gHideAltitudeMax);
    }

    hiitt.setMode(getStorageValue("hiit_mode", WhatHiitt.HiitDisabled) as WhatHiitt.HiitMode);
    hiitt.setSound(getStorageValue("hiit_sound", WhatHiitt.StartOnlySound) as WhatHiitt.HiitSound);
    hiitt.setStartOnPerc(getStorageValue("hiit_startperc", 0) as Number);
    hiitt.setStopOnPerc(getStorageValue("hiit_stopperc", 0) as Number);
    hiitt.setStartCountDownSeconds(getStorageValue("hiit_countdown", 3) as Number);
    hiitt.setStopCountDownSeconds(getStorageValue("hiit_inactivity", 10) as Number);
    hiitt.setMinimalElapsedSeconds(getStorageValue("hiit_valid_sec", 30) as Number);
    hiitt.setMinimalRecoverySeconds(getStorageValue("hiit_recovery_sec", 300) as Number);

    var metrics = getWhatMetrics();
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
      gMetrics.initHrZones(heartRateZones);
    }

    gDebug = getStorageValue("debug", gDebug) as Boolean;
    gShowColors = getStorageValue("show_colors", gShowColors) as Boolean;
    gShowGrid = getStorageValue("show_grid", gShowGrid) as Boolean;
    gShowTimer = getStorageValue("show_timer", gShowTimer) as Boolean;

    // gWideFieldShowDistance = getStorageValue("wf_toggle_heading", gWideFieldShowDistance) as Boolean;

    gHideAltitudeMin = getStorageValue("pressure_altmin", 0) as Number;
    gHideAltitudeMax = getStorageValue("pressure_altmax", 0) as Number;
    gShowMeanSeaLevel = getStorageValue("pressure_show_meansealevel", gShowMeanSeaLevel) as Boolean;

    gShowPowerBalance = getStorageValue("show_powerbalance", gShowPowerBalance) as Boolean;
    gShowPowerBattery = getStorageValue("show_powerbattery", gShowPowerBattery) as Boolean;
    gShowPowerBattTime = getStorageValue("show_powerbatterytime", gShowPowerBattTime) as Boolean;
    gShowPowerPerWeight = getStorageValue("show_powerperweight", gShowPowerPerWeight) as Boolean;
    gShowPowerAverage = getStorageValue("show_poweraverage", gShowPowerAverage) as Boolean;

    gPowerCountdownToFallBack = getStorageValue("power_countdowntofallback", gPowerCountdownToFallBack) as Number;

    var hours = getStorageValue("metric_pbattmaxhour", gPowerBattMaxSeconds / 3600) as Number;
    if (hours > 0 and hours < 1000) {
      gPowerBattMaxSeconds = hours * 60 * 60;
    }
    gPowerBattOperTimeCharched = getStorageValue("metric_pbattopertimecharched", 0) as Number;
    gPowerBattFullyCharched = getStorageValue("metric_pbattfullycharched", gPowerBattFullyCharched) as Boolean;
    gPowerBattSetRemainingHour = getStorageValue("metric_pbattsetremaininghour", 0) as Number;

    if (gShowPowerBalance or gShowPowerBattery) {
      gMetrics.initPowerBalance();
    }
    gMetrics.initWeight();
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
var gHiitt as WhatHiitt?; // = new WhatHiitt(); Gives weird symbol not found error
var gMetrics as WhatMetrics?; // = new WhatMetrics(); Gives weird symbol not found error
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
var gShowTimer as Boolean = false;
var gShowPowerBalance as Boolean = true;
var gShowPowerBattery as Boolean = true;
var gShowPowerPerWeight as Boolean = false;
var gShowPowerAverage as Boolean = false;

var gShowPowerBattTime as Boolean = false;
var gPowerBattMaxSeconds as Number = 0;
var gPowerBattOperTimeCharched as Number = 0;
var gPowerBattFullyCharched as Boolean = false;
var gPowerBattSetRemainingHour as Number = 0;

// var gWideFieldShowDistance as Boolean = false;
// var gWideFieldShowDistanceDestination as Boolean = false;
var gHideAltitudeMin as Number = -10;
var gHideAltitudeMax as Number = 10;
var gShowMeanSeaLevel as Boolean = true;
var gPowerCountdownToFallBack as Number = 10;
