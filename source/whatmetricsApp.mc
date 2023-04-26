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
    return (
      [new $.DataFieldSettingsView(), new $.DataFieldSettingsDelegate()] as
      Array<Views or InputDelegates>
    );
  }
  function onSettingsChanged() {
    gHiitt.updateProfile();
    if (Storage.getValue("hiit_mode") == null) {
      Storage.setValue("hiit_mode", WhatHiitt.HiitDisabled);
      Storage.setValue("hiit_sound", WhatHiitt.NoSound);
      Storage.setValue("hiit_startperc", 150);
      Storage.setValue("hiit_stopperc", 100);
      Storage.setValue("hiit_countdown", 3);
      Storage.setValue("hiit_inactivity", 10);

      Storage.setValue("target_ftp", gTargetFtp);
      Storage.setValue("target_speed", gTargetSpeed);
      Storage.setValue("target_cadence", gTargetCadence);
      Storage.setValue("target_calories", gTargetCalories);
      Storage.setValue("target_grade", gTargetGrade);
      Storage.setValue("target_altitude", gTargetAltitude);

      Storage.setValue("metric_ppersec", 3);
      Storage.setValue("metric_gradews", 4);
    }

    gHiitt.setMode(
      getStorageValue("hiit_mode", WhatHiitt.HiitDisabled) as WhatHiitt.HiitMode
    );
    gHiitt.setSound(
      getStorageValue("hiit_sound", WhatHiitt.NoSound) as WhatHiitt.HiitSound
    );
    gHiitt.setStartOnPerc(getStorageValue("hiit_startperc", 0) as Number);
    gHiitt.setStopOnPerc(getStorageValue("hiit_stopperc", 0) as Number);
    gHiitt.setStartCountDownSeconds(
      getStorageValue("hiit_countdown", 0) as Number
    );
    gHiitt.setStopCountDownSeconds(
      getStorageValue("hiit_inactivity", 0) as Number
    );

    gMetrics.setPowerPerSec(getStorageValue("metric_ppersec", 0) as Number);
    gMetrics.setGradeWindowSize(getStorageValue("metric_gradews", 0) as Number);

    gTargetFtp = getStorageValue("target_ftp", 0) as Number;    
    gTargetSpeed = getStorageValue("target_speed", 0) as Number;    
    gTargetCadence = getStorageValue("target_cadence", 0) as Number;    
    gTargetCalories = getStorageValue("target_calories", 0) as Number;    
    gTargetGrade = getStorageValue("target_grade", 0) as Number;    
    gTargetAltitude = getStorageValue("target_altitude", 0) as Number;    

    var heartRateZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
    if (heartRateZones.size() > 0) {
      gTargetHeartRate = heartRateZones[heartRateZones.size() - 1];
    }
    
    gDebug = getStorageValue("debug", false) as Boolean;    
    gShowColors = getStorageValue("show_colors", false) as Boolean;    
  }
}

function getApp() as whatmetricsApp {
  return Application.getApp() as whatmetricsApp;
}

var gHiitt as WhatHiitt = new WhatHiitt();
var gMetrics as WhatMetrics = new WhatMetrics();
var gTargetFtp as Number = 250;
var gTargetSpeed as Number = 30;
var gTargetCadence as Number = 90;
var gTargetCalories as Number = 2000;
var gTargetGrade as Number = 8;
var gTargetAltitude as Number = 1000;
var gDebug as Boolean = false;
var gShowColors as Boolean = false;
var gTargetHeartRate as Number = 200;