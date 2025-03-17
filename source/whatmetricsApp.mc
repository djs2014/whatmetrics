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
    if (!version.equals("1.0.4")) {
      Storage.clearValues();
      Storage.setValue("version", "1.0.4");
      Storage.setValue("resetDefaults", true);
    }

    var reset = Storage.getValue("resetDefaults");
    if (reset == null || (reset as Boolean)) {
      Storage.setValue("resetDefaults", false);

      Storage.setValue("hiit_mode", WhatHiitt.HiitWhenActive);
      Storage.setValue("hiit_sound", WhatHiitt.StartOnlySound);
      Storage.setValue("hiit_startperc", 150);
      Storage.setValue("hiit_stopperc", 100);
      Storage.setValue("hiit_countdown", 3);
      Storage.setValue("hiit_inactivity", 10);
      Storage.setValue("hiit_valid_sec", 30);
      Storage.setValue("hiit_recovery_sec", 300);

      Storage.setValue("metric_ppersec", 3);
      Storage.setValue("metric_gradews", 4);
      Storage.setValue("metric_grademinrise", 0);
      Storage.setValue("metric_grademinrun", 20);

      Storage.setValue("debug", $.gDebug);
      Storage.setValue("show_colors", $.gShowColors);
      Storage.setValue("show_grid", $.gShowGrid);
      Storage.setValue("show_average", true);
      Storage.setValue("show_np_as_avg", $.gShowNPasAverage);
      Storage.setValue("np_skip_zero", false);

      // @@
      // Storage.setValue("show_powerbalance", $.gShowPowerBalance);
      Storage.setValue("show_powerbattery", $.gShowPowerBattery);

      Storage.setValue("power_dual_sec_fallback", 0);
      Storage.setValue("power_times_two", false);

      Storage.setValue("altitude_start_fb", $.gAltitudeFallbackStart);
      Storage.setValue("altitude_end_fb", $.gAltitudeFallbackEnd);
      Storage.setValue("grade_start_fb", $.gGradeFallbackStart);
      Storage.setValue("grade_end_fb", $.gGradeFallbackEnd);
      Storage.setValue("power_countdowntofb", 10);
      Storage.setValue("cadence_countdowntofb", 30);

      $.gLargeField =
        [FL8Fields, FTGrade, FTBearing, FTHeartRate, FTPower, FTSpeed, FTAltitude, FTCadence, FTHiit] as Array<Number>;
      $.gWideField =
        [FL6Fields, FTGrade, FTDistanceNext, FTHeartRate, FTPower, FTSpeed, FTAltitude, FTCadence, FTHiit] as
        Array<Number>;
      $.gSmallField =
        [FL4Fields, FTSpeed, FTPower, FTHeartRate, FTCadence, FTGrade, FTAltitude, FTCadence, FTHiit] as Array<Number>;
      Storage.setValue("large_field", $.gLargeField as Lang.Array<Application.PropertyValueType>);
      Storage.setValue("wide_field", $.gWideField as Lang.Array<Application.PropertyValueType>);
      Storage.setValue("small_field", $.gSmallField as Lang.Array<Application.PropertyValueType>);

      Storage.setValue("large_field_zen", ZMWhenMoving);
      Storage.setValue("wide_field_zen", ZMWhenMoving);
      Storage.setValue("small_field_zen", ZMOn);
      Storage.setValue("large_field_bp", BPBottom);
      Storage.setValue("wide_field_bp", BPTop);
      Storage.setValue("small_field_bp", BPOff);

      $.gFallbackFields = [];
      setFallbackField(FTDistanceNext, FTDistanceDest);
      setFallbackField(FTDistanceDest, FTDistance);
      setFallbackField(FTPower, FTDistance);
      setFallbackField(FTPowerPerWeight, FTDistance);
      setFallbackField(FTHeartRate, FTTimeElapsed);
      setFallbackField(FTHeartRateZone, FTTimeElapsed);
      setFallbackField(FTHiit, FTClock);
      setFallbackField(FTVo2MaxHiit, FTHiit);
      setFallbackField(FTAltitude, FTPressureAtSea);
      setFallbackField(FTEta, FTAltitude);
      setFallbackField(FTVo2MaxProfile, FTEta);
      setFallbackField(FTEtr, FTAltitude);
      setFallbackField(FTCadence, FTAverageSpeed);
      setFallbackField(FTNormalizedPower, FTTimeElapsed);

      Storage.setValue("fields_fallback", $.gFallbackFields as Lang.Array<Application.PropertyValueType>);

      $.gGraphic_fields = [FTTrainingStressScore, FTHeartRateZone, FTUnknown, FTUnknown, FTUnknown] as Array<Number>;
      Storage.setValue("graphic_fields", $.gGraphic_fields as Lang.Array<Application.PropertyValueType>);
      Storage.setValue("gf_line_width", 7);
      Storage.setValue("gf_zones", 5);
      Storage.setValue("show_graphic_fields", true);

      Storage.setValue("demofields", false);
      Storage.setValue("demofields_wait", 2);
      Storage.setValue("demofields_roundtrip", 1);

      Storage.setValue("show_icon", true);
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

    if ((getStorageValue("target_ftp", 0) as Number) == 0) {
      Storage.setValue("target_ftp", $.gTargetFtp);
      Storage.setValue("target_speed", $.gTargetSpeed);
      Storage.setValue("target_cadence", $.gTargetCadence);
      Storage.setValue("target_calories", $.gTargetCalories);
      Storage.setValue("target_grade", $.gTargetGrade);
      Storage.setValue("target_altitude", $.gTargetAltitude);
      Storage.setValue("target_hrzone", 4);
      Storage.setValue("target_if", $.gTargetIF);
      Storage.setValue("target_tss", $.gTargetTSS);
      Storage.setValue("target_distance", $.gTargetDistance);
      Storage.setValue("target_distance_route", $.gTargetDistanceUseRoute);
    }
    $.gTargetFtp = getStorageValue("target_ftp", $.gTargetFtp) as Number;
    $.gTargetSpeed = getStorageValue("target_speed", $.gTargetSpeed) as Number;
    $.gTargetCadence = getStorageValue("target_cadence", $.gTargetCadence) as Number;
    $.gTargetCalories = getStorageValue("target_calories", $.gTargetCalories) as Number;
    $.gTargetGrade = getStorageValue("target_grade", $.gTargetGrade) as Number;
    $.gTargetAltitude = getStorageValue("target_altitude", $.gTargetAltitude) as Number;
    $.gTargetIF = getStorageValue("target_if", $.gTargetIF) as Float;
    $.gTargetTSS = getStorageValue("target_tss", $.gTargetTSS) as Number;
    $.gTargetDistance = getStorageValue("target_distance", $.gTargetDistance) as Number;
    $.gTargetDistanceUseRoute = getStorageValue("target_distance_route", $.gTargetDistanceUseRoute) as Boolean;

    var targetHrZone = getStorageValue("target_hrzone", 4) as Number;
    var heartRateZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
    if (heartRateZones.size() > 0) {
      if (targetHrZone > 0 and targetHrZone < heartRateZones.size()) {
        $.gTargetHeartRate = (heartRateZones[targetHrZone - 1] + heartRateZones[targetHrZone]) / 2;
      } else {
        $.gTargetHeartRate = heartRateZones[heartRateZones.size() - 1];
      }
      metrics.initHrZones(heartRateZones);
    }

    // @@ TODO init array fields size of 9
    $.gLargeField =
      getStorageValue("large_field", $.gLargeField as Lang.Array<Application.PropertyValueType>) as Array<Number>;
    $.gWideField =
      getStorageValue("wide_field", $.gWideField as Lang.Array<Application.PropertyValueType>) as Array<Number>;
    $.gSmallField =
      getStorageValue("small_field", $.gSmallField as Lang.Array<Application.PropertyValueType>) as Array<Number>;

    $.gLargeFieldZen = getStorageValue("large_field_zen", $.gLargeFieldZen) as ZenMode;
    $.gWideFieldZen = getStorageValue("wide_field_zen", $.gWideFieldZen) as ZenMode;
    $.gSmallFieldZen = getStorageValue("small_field_zen", $.gSmallFieldZen) as ZenMode;

    $.gFallbackFields =
      getStorageValue("fields_fallback", $.gFallbackFields as Lang.Array<Application.PropertyValueType>) as
      Array<Number>;
    while ($.gFallbackFields.size() < $.FieldTypeCount) {
      $.gFallbackFields.add(FTUnknown);
    }

    // @@TODO refactor + barpostion   
    // $.gLargeFieldGraphic = getStorageValue("large_field_bar", $.gLargeFieldGraphic) as Array<Number>;
    // $.gWideFieldGraphic = getStorageValue("wide_field_bar", $.gWideFieldGraphic) as Array<Number>;
    // $.gSmallFieldGraphic = getStorageValue("small_field_bar", $.gSmallFieldGraphic) as Array<Number>;

    // @@
    $.gGraphic_fields =
      getStorageValue("graphic_fields", $.gGraphic_fields as Lang.Array<Application.PropertyValueType>) as
      Array<Number>;
    while ($.gGraphic_fields.size() < 5) {
      $.gGraphic_fields.add(FTUnknown);
    }
    $.gShow_graphic_fields = getStorageValue("show_graphic_fields", $.gShow_graphic_fields) as Boolean;
    if ($.gShow_graphic_fields) {
      $.gLargeFieldBp = getStorageValue("large_field_bp", $.gLargeFieldBp) as BarPosition;
      $.gWideFieldBp = getStorageValue("wide_field_bp", $.gWideFieldBp) as BarPosition;
      $.gSmallFieldBp = getStorageValue("small_field_bp", $.gSmallFieldBp) as BarPosition;
    } else {
      $.gLargeFieldBp = BPOff;
      $.gWideFieldBp = BPOff;
      $.gSmallFieldBp = BPOff;
    }
    $.gGraphic_fields_line_width = getStorageValue("gf_line_width", $.gGraphic_fields_line_width) as Number;
    $.gGraphic_fields_zones = getStorageValue("gf_zones", $.gGraphic_fields_zones) as Number;

    $.gDebug = getStorageValue("debug", $.gDebug) as Boolean;
    $.gShowColors = getStorageValue("show_colors", $.gShowColors) as Boolean;
    $.gShowGrid = getStorageValue("show_grid", $.gShowGrid) as Boolean;
    $.gShowAverageWhenPaused = getStorageValue("show_average", $.gShowAverageWhenPaused) as Boolean;

    $.gAltitudeFallbackStart = getStorageValue("altitude_start_fb", 0) as Number;
    $.gAltitudeFallbackEnd = getStorageValue("altitude_end_fb", 0) as Number;
    $.gGradeFallbackStart = getStorageValue("grade_start_fb", 0) as Number;
    $.gGradeFallbackEnd = getStorageValue("grade_end_fb", 0) as Number;

    $.gShowIcon = getStorageValue("show_icon", $.gShowIcon) as Boolean;

    $.gShowPowerBattery = getStorageValue("show_powerbattery", $.gShowPowerBattery) as Boolean;
    $.gShowNPasAverage = getStorageValue("show_np_as_avg", $.gShowNPasAverage) as Boolean;
    var NPSkipZero = getStorageValue("np_skip_zero", false) as Boolean;
    metrics.initNP(NPSkipZero);
    // @@ from user profile possible?
    metrics.setFTP($.gTargetFtp);

    // @@ TODO refactor
    var powerDualSecFallback = getStorageValue("power_dual_sec_fallback", 0) as Number;
    var powerTimesTwo = getStorageValue("power_times_two", false) as Boolean;
    $.gPowerCountdownToFallBack = getStorageValue("power_countdowntofb", $.gPowerCountdownToFallBack) as Number;
    $.gCadenceCountdownToFallBack = getStorageValue("cadence_countdowntofb", $.gCadenceCountdownToFallBack) as Number;
    metrics.initPowerBalance(powerDualSecFallback, powerTimesTwo);

    metrics.initWeight();

    var demoFields = getStorageValue("demofields", false) as Boolean;
    if (demoFields) {
      Storage.setValue("demofields", false);
      $.gDemoFieldsWait = getStorageValue("demofields_wait", 2) as Number;
      $.gDemoFieldsRoundTrip = getStorageValue("demofields_roundtrip", 1) as Number;
    } else {
      $.gDemoFieldsRoundTrip = 0;
    }
    $.gPause_x_offset = getStorageValue("pause_x_offset", 10) as Number;
  }

  hidden function setFallbackField(field as FieldType, fallback as FieldType) as Void {
    while ($.gFallbackFields.size() < $.FieldTypeCount) {
      $.gFallbackFields.add(FTUnknown);
    }
    $.gFallbackFields[field as Number] = fallback;
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
var gTargetCalories as Number = 4000;
var gTargetGrade as Number = 8;
var gTargetAltitude as Number = 1000;
var gTargetHeartRate as Number = 200;
var gTargetIF as Float = 1.2f;
var gTargetTSS as Number = 450;
var gTargetDistance as Number = 0;
var gTargetDistanceUseRoute as Boolean = true;

var gDebug as Boolean = false;

var gShow_graphic_fields as Boolean = true;
var gGraphic_fields_line_width as Number = 7;
var gGraphic_fields_zones as Number = 5;

var gShowColors as Boolean = false;
var gShowGrid as Boolean = true;
var gShowAverageWhenPaused as Boolean = false;

var gShowNPasAverage as Boolean = false;

// @@ refactor
// var gShowPowerBalance as Boolean = true;
var gShowPowerBattery as Boolean = true;
var gShowIcon as Boolean = true;

var gPowerCountdownToFallBack as Number = 10;
var gCadenceCountdownToFallBack as Number = 30;

var gAltitudeFallbackStart as Number = -10;
var gAltitudeFallbackEnd as Number = 10;
var gGradeFallbackStart as Number = -2;
var gGradeFallbackEnd as Number = 2;

var gLargeField as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
var gWideField as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
var gSmallField as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;

// var gLargeFieldGraphic as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
// var gWideFieldGraphic as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
// var gSmallFieldGraphic as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
var gGraphic_fields as Array<Number> = [] as Array<Number>;

var gLargeFieldZen as ZenMode = ZMOff;
var gWideFieldZen as ZenMode = ZMOff;
var gSmallFieldZen as ZenMode = ZMOff;

var gLargeFieldBp as BarPosition = BPBottom;
var gWideFieldBp as BarPosition = BPTop;
var gSmallFieldBp as BarPosition = BPOff;

var gFallbackFields as Array<Number> = [] as Array<Number>;

var gDemoFieldsWait as Number = 2;
var gDemoFieldsRoundTrip as Number = 0;

var gPause_x_offset as Number = 10;
