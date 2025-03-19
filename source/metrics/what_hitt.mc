import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.System;
import Toybox.Attention;
import Toybox.Time;
import Toybox.Math;
import Toybox.Time.Gregorian;
// Hiit
// Start when enabled and x seconds power >= % of target -> show start counter / beep
// Property Hiit started
// Stop when enabled and x seconds power <= % of target -> show stop counter / beep
// Calc vo2 max approx + add Hiit counter

class WhatHiitt {
  enum HiitStatus {
    InActive = 0,
    WarmingUp = 1,
    CoolingDown = 2,
    Active = 3,
  }

  enum HiitMode {
    HiitDisabled = 0,
    HiitWhenActive = 1, // visible when active
    HiitAlwaysOn = 2, // always active
  }
  enum HiitSound {
    NoSound = 0,
    StartOnlySound = 1,
    LowNoise = 2,
    LoudNoise = 3,
  }

  hidden var hiitMode as HiitMode = HiitDisabled;
  hidden var hiitSound as HiitSound = LowNoise;
  hidden var soundEnabled as Boolean = false;

  hidden var hiitPerformed as Number = 0;
  hidden var hiitStatus as HiitStatus = InActive;
  hidden var hiitStartOnPerc as Number = 150;
  hidden var hiitStartCountDownSeconds as Number = 5;
  hidden var hiitStopOnPerc as Number = 100;
  hidden var hiitStopCountDownSeconds as Number = 10;
  hidden var hiitCounter as Number = 0;
  hidden var hiitElapsedTime as Time.Moment?;
  hidden var hiitElapsedRecoveryTime as Time.Moment?;

  hidden var minimalElapsedSeconds as Number = 30;
  hidden var minimalRecoverySeconds as Number = 300;
  hidden var mValidHiitPerformed as Boolean = false;

  hidden var activityPaused as Boolean = false;
  hidden var userPaused as Boolean = false;

  hidden var stoppingCountDownSeconds as Number = 5;
  hidden var stoppingTime as Time.Moment?;

  hidden var calcVo2Max as Boolean = false;
  hidden var playTone as Boolean = true;

  hidden var hiitScores as Array<Number> = [] as Array<Number>; //[50,30,60,50,61]; // @@ TEST
  hidden var hiitDurations as Array<Number> = [] as Array<Number>; //[30,31,30,35,40]; // @@ TEST
  hidden var currentDuration as Number = 0;
  hidden var currentScore as Number = 0;

  hidden var currentTimerState as Number = Activity.TIMER_STATE_OFF;
  hidden var userWeightKg as Float = 0.0f;
  hidden var powerTicks as Number = 0;
  hidden var avgPowerPerSec as Double = 0.0d;
  hidden var userVo2maxCycling as Number = 0;
  hidden var userGender as Number = 0;
  hidden var userAge as Number = 0;
  hidden var userVo2MaxChartKey as String = "";
  hidden var vo2MaxChartKey as String = "";
  hidden var vo2MaxChart as Array<Number>  = [] as Array<Number>;
  
  /* TODO
  hiit demo
  - hiitStartCountDownSeconds (power is hiitStartOnPerc + 10)
  - minimalElapsedSeconds (power is hiitStopOnPerc + 10)
  - hiitStopCountDownSeconds (power is hiitStopOnPerc - 10)
  - minimalRecoverySeconds (power is hiitStopOnPerc - 10)
  - stops when entering settings
  */
  hidden var isDemo as Boolean = false;
  hidden var demoCounter as Number = 0;

  function initialize() {}

  function updateProfile() as Void {
    var profile = UserProfile.getProfile();
    if (profile.weight != null) {
      var weight = profile.weight as Number;
      userWeightKg = weight / 1000.0;
    }
    if (profile.vo2maxCycling != null) {
      userVo2maxCycling = profile.vo2maxCycling as Number;
    }
    // TODO get sex / age -> get vo2max percentile
    userGender = 1; // 0 female, 1 male
    if (profile.gender != null) {
      userGender = profile.gender as Number;
      if (userGender != 0) { userGender = 1; }
    }
    userAge = 0;
    if (profile.birthYear != null) {
      var birthYear = profile.birthYear as Number;
      if (birthYear > 0) {
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        userAge = today.year - birthYear;
      }      
    }
    userVo2MaxChartKey = Lang.format("$1$:$2$",[userAge,userGender]);
  }

  function setDemo(demo as Boolean) as Void {
    isDemo = demo;
    demoCounter = 0;
  }

  function setMode(hiitMode as HiitMode) as Void {
    self.hiitMode = hiitMode;
    soundEnabled = (self.hiitSound as HiitSound) != NoSound && hiitMode != HiitDisabled;    
  }
  function setSound(hiitSound as HiitSound) as Void {
    self.hiitSound = hiitSound;
    soundEnabled = (self.hiitSound as HiitSound) != NoSound && hiitMode != HiitDisabled;        
  }

  function setStartOnPerc(hiitStartOnPerc as Number) as Void {
    self.hiitStartOnPerc = hiitStartOnPerc;
  }
  function setStopOnPerc(hiitStartOnPerc as Number) as Void {
    self.hiitStopOnPerc = hiitStopOnPerc;
  }
  function setStartCountDownSeconds(hiitStartCountDownSeconds as Number) as Void {
    self.hiitStartCountDownSeconds = hiitStartCountDownSeconds;
  }
  function setStopCountDownSeconds(hiitStopCountDownSeconds as Number) as Void {
    self.hiitStopCountDownSeconds = hiitStopCountDownSeconds;
  }

  function setMinimalElapsedSeconds(minimalElapsedSeconds as Number) as Void {
    self.minimalElapsedSeconds = minimalElapsedSeconds;
  }
  function setMinimalRecoverySeconds(minimalRecoverySeconds as Number) as Void {
    self.minimalRecoverySeconds = minimalRecoverySeconds;
  }

  function checkPerc() as Array<Number> {
    if (hiitStartOnPerc <= hiitStopOnPerc) {
      hiitStartOnPerc = 150;
      hiitStopOnPerc = 100;
      return [hiitStartOnPerc, hiitStopOnPerc] as Array<Number>;
    }
    return [];
  }

  function isEnabled() as Boolean {
    if (isDemo || hiitMode == HiitAlwaysOn) {
      return true;
    }
    if (hiitMode == HiitDisabled) {
      return false;
    }
    // HiitWhenActive
    return isHiitInProgress() || isActivityPaused() && hiitPerformed > 0; 
  }
 
  function isActivityPaused() as Boolean {
    return activityPaused;
  }

  hidden function ActivityStarted(timerState as Number?) as Boolean {
    if (timerState == null) {
      return false;
    }

    var started = currentTimerState == Activity.TIMER_STATE_OFF && timerState == Activity.TIMER_STATE_ON;
    currentTimerState = timerState;
    return started;
  }

  // Hiit vo2max
  function getAverageHiitScore() as Number {
    if (hiitScores.size()==0) {
      return 0;
    }
    return Math.mean(hiitScores as Lang.Array<Lang.Numeric>).toNumber();
  }
  function getHitScores() as Array<Number> {
    return hiitScores;
  }
  function getHitDurations() as Array<Number> {
    isHiitInProgress();
    return hiitDurations;
  }

  function wasValidHiit() as Boolean {
    return mValidHiitPerformed;
  }

  function isHiitInProgress() as Boolean {
    return hiitStatus != InActive || getRecoveryElapsedSeconds() > 0;
  }

  function getHistStatusAsString() as String {
    switch (hiitStatus) {
      case InActive:
        return "--";
      case WarmingUp:
        return "warming up";
      case CoolingDown:
        return "cooling down";
      case Active:
        return "active";
      default:
        return "";
    }
  }
  function compute(info as Activity.Info, percOfTarget as Numeric, power as Number) as Void {
    if (isDemo) {
      var origPercOfTarget = percOfTarget;
      percOfTarget = getDemoPercOfTarget(percOfTarget);
      System.println(["Demo", power, demoCounter, origPercOfTarget, "->", percOfTarget, "status", hiitStatus]);
    }
    calcVo2Max = (hiitStatus as HiitStatus) == Active;
    updateMetrics(info);
    updateRecoveryTime();
    if (activityPaused) {
      hiitStatus = InActive;
      hiitCounter = 0;
      hiitElapsedRecoveryTime = null;
      hiitElapsedTime = null;
      playTone = soundEnabled;
      return;
    }
    //System.println(percOfTarget);

    switch (hiitStatus) {
      case InActive:
        // System.println("InActive");
        if (percOfTarget >= hiitStartOnPerc) {
          // Start warming up for x seconds
          hiitStatus = WarmingUp;
          hiitCounter = hiitStartCountDownSeconds;
          playTone = soundEnabled;
        }
        break;
      case WarmingUp:
        // System.println("Warming up");
        hiitCounter = hiitCounter - 1;
        hiitAttentionWarmingUp(playTone);
        mValidHiitPerformed = false;

        if (percOfTarget < hiitStartOnPerc) {
          // Stop warming up
          hiitStatus = InActive;
          hiitCounter = 0;
        } else {
          if (hiitCounter == 0) {
            // End of warming up, start Hiit
            resetAveragePower();
            hiitStatus = Active;
            hiitElapsedRecoveryTime = null;
            currentDuration = 0;
            currentScore = 0;
            hiitElapsedTime = Time.now();
            hiitAttentionStart();
          }
        }
        break;
      case CoolingDown:
        // System.println("Cooling down");
        hiitAttentionCoolingdown(playTone);
        hiitCounter = hiitCounter - 1;

        if (percOfTarget >= hiitStopOnPerc) {
          // Stop cooling down
          hiitStatus = Active;
          hiitCounter = 0;
        } else {
          if (hiitCounter == 0) {
            hiitStatus = InActive;

            // currentDuration = actual hiit seconds just before cooling down
            if (currentDuration >= minimalElapsedSeconds) {
              hiitAttentionStop();
              // Proper Hiit :-)
              hiitPerformed = hiitPerformed + 1;
              hiitElapsedRecoveryTime = Time.now();
              hiitScores.add(currentScore);
              hiitDurations.add(currentDuration);
            } else {
              // No proper Hiit (no sound)
              hiitStatus = InActive;
              hiitCounter = 0;
              hiitElapsedRecoveryTime = null;
              currentScore = 0;
              currentDuration = 0;
            }
            hiitElapsedTime = null;
          }
        }
        break;
      case Active:
        // System.println("Active");

        mValidHiitPerformed = getElapsedSeconds() >= minimalElapsedSeconds;
        if (percOfTarget < hiitStopOnPerc) {
          hiitStatus = CoolingDown;
          hiitCounter = hiitStopCountDownSeconds;
          hiitAttentionWarn();
          currentDuration = getElapsedSeconds();
          // only sound when proper Hiit
          playTone = soundEnabled && mValidHiitPerformed;
          currentScore = getVo2Max();
        } else {
          addAveragePower(power);
        }
        break;
    }

    // if (!isEnabled()) {
    //   hiitElapsedRecoveryTime = null;
    //   hiitElapsedTime = null;
    //   return;
    // }

  }

  hidden function resetAveragePower() as Void {
    powerTicks = 0;
    avgPowerPerSec = 0.0d;
  }
  hidden function addAveragePower(power as Number) as Void {
    // [ avg' * (n-1) + x ] / n
    powerTicks = powerTicks + 1;
    avgPowerPerSec = (avgPowerPerSec * (powerTicks - 1) + power) / powerTicks.toDouble();
    // System.println(Lang.format("p $1$ ticks $2$ avg $3$", [power, powerTicks, avgPowerPerSec]));
  }

  hidden function updateRecoveryTime() as Void {
    if (hiitElapsedRecoveryTime == null) {
      return;
    }
    if (!stopping()) {
      stoppingTime = null;
      return;
    }
    if (stoppingTime == null) {
      stoppingTime = Time.now();
    }
    var seconds = Time.now().value() - (stoppingTime as Time.Moment).value();
    if (seconds >= stoppingCountDownSeconds) {
      hiitElapsedRecoveryTime = null;
    }
  }

  hidden function updateMetrics(info as Activity.Info) as Void {
    if (isDemo) {
      activityPaused = false;
      userPaused = false;
      if (demoCounter==0) {
        reset();
      }
      return;
    }

    var currentSpeed = getActivityValue(info, :currentSpeed, 0.0f) as Float;
    var currentCadence = getActivityValue(info, :currentCadence, 0.0f) as Float;
    userPaused = currentSpeed == 0.0f || (info has :currentCadence and currentCadence == 0);

    if (info has :timerState) {
      if (ActivityStarted(info.timerState)) {
        reset();
      }
      activityPaused = info.timerState == Activity.TIMER_STATE_PAUSED;
    } else {
      activityPaused = false;
    }

   
  }

  hidden function getDemoPercOfTarget(percOfTarget as Numeric) as Numeric {
    // Based on seconds in demo give the perc of target
    demoCounter = demoCounter + 1;
    if (demoCounter <= hiitStartCountDownSeconds + 1) {
      return hiitStartOnPerc + 10;
    }
    if (demoCounter <= (hiitStartCountDownSeconds + minimalElapsedSeconds + 10)) {
      return hiitStartOnPerc + 10;
    }
    // minimalRecoverySeconds -> 
    var recoverySeconds = minimalRecoverySeconds;
    if (recoverySeconds > 30) {
      recoverySeconds = 30;
    }
    if (demoCounter <= (hiitStartCountDownSeconds + minimalElapsedSeconds + 10 + hiitStopCountDownSeconds + recoverySeconds + 1)) {
      var perc = hiitStopOnPerc - 10;
      if (perc <= 0) {
        perc = 1;
      }
      return perc;
    }

    // End of demo
    isDemo = false;
    demoCounter = 0;
    return percOfTarget;
  }

  hidden function stopping() as Boolean {
    return activityPaused || userPaused;
  }

  hidden function reset() as Void {
    hiitScores = [] as Array<Number>;
    hiitDurations = [] as Array<Number>;
    hiitPerformed = 0;
    currentDuration = 0;
    currentScore = 0;
    hiitCounter = 0;
    hiitElapsedRecoveryTime = null;
    hiitElapsedTime = null;
    resetAveragePower();
  }

  hidden function hiitAttentionWarmingUp(playTone as Boolean) as Void {
    if (Attention has :playTone && soundEnabled && playTone) {
      if (Attention has :ToneProfile) {
        var toneProfileBeeps = [new Attention.ToneProfile(1500, 50)] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      } else {
        Attention.playTone(Attention.TONE_LOUD_BEEP);
      }
    }
  }

  hidden function hiitAttentionCoolingdown(playTone as Boolean) as Void {
    if (Attention has :playTone && soundEnabled && playTone && hiitSound != StartOnlySound) {
      if (Attention has :ToneProfile && hiitSound == LowNoise) {
        var toneProfileBeeps = [new Attention.ToneProfile(1000, 50)] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      } else {
        Attention.playTone(Attention.TONE_LOUD_BEEP);
      }
    }
  }

  hidden function hiitAttentionWarn() as Void {
    if (Attention has :playTone && soundEnabled) {
      if (Attention has :ToneProfile) {
        var toneProfileBeeps =
          [new Attention.ToneProfile(1000, 40), new Attention.ToneProfile(1500, 100)] as
          Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      }
    }
  }

  hidden function hiitAttentionStart() as Void {
    if (Attention has :playTone && soundEnabled) {
      if (Attention has :ToneProfile && hiitSound == LowNoise) {
        var toneProfileBeeps = [new Attention.ToneProfile(1100, 150)] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      } else {
        Attention.playTone(Attention.TONE_ALERT_HI);
      }
    }
  }

  hidden function hiitAttentionStop() as Void {
    if (Attention has :playTone && soundEnabled && hiitSound != StartOnlySound) {
      if (Attention has :ToneProfile && hiitSound == LowNoise) {
        var toneProfileBeeps =
          [
            new Attention.ToneProfile(1100, 100),
            new Attention.ToneProfile(800, 80),
            new Attention.ToneProfile(500, 30),
          ] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      } else {
        Attention.playTone(Attention.TONE_ALERT_LO);
      }
    }
  }

  function getElapsedSeconds() as Number {
    // @@ Warn if greater than 60 seconds
    if (hiitElapsedTime == null) {
      return 0;
    }
    return Time.now().value() - (hiitElapsedTime as Time.Moment).value();
  }

  // Count down to 0
  function getRecoveryElapsedSeconds() as Number {
    // @@ Stop if greater than 6 minutes , Setting
    if (hiitElapsedRecoveryTime == null) {
      return 0;
    }
    var seconds = Time.now().value() - (hiitElapsedRecoveryTime as Time.Moment).value();
    var leftOver = minimalRecoverySeconds - seconds;
    if (leftOver < 0) {
      hiitElapsedRecoveryTime = null;
      return 0;
    }
    return leftOver;
  }

  // Determine if its first seconds of recovery
  function isStartOfRecovery(endOfStartSeconds as Number) as Boolean {    
    if (hiitElapsedRecoveryTime == null) {
      return false;
    }
    var seconds = Time.now().value() - (hiitElapsedRecoveryTime as Time.Moment).value();
    return seconds < endOfStartSeconds;
  }

  function getNumberOfHits() as Number {
    return hiitPerformed;
  }

  function getCounter() as Number {
    return hiitCounter;
  }

  // vo2max = ((6min pow er * 10.8) / weight) + 7
  // https://www.michael-konczer.com/en/training/calculators/calculate-vo2max
  function getVo2Max() as Number {
    if (userWeightKg == 0.0f) {
      return 0;
    }
    var pp6min = avgPowerPerSec.toNumber();
    return ((pp6min * 10.8) / userWeightKg + 7).toNumber();
  }

  function getProfileVo2Max() as Number {
    return userVo2maxCycling;
  }

  function getVo2MaxPercentile(vo2max as Number) as Number {
    if (userAge == 0) { return 0; }

    // age and gender won't change during a ride, so cache result.
    if (!userVo2MaxChartKey.equals(vo2MaxChartKey)) {
      var chart;
      if (userGender == 0) {
        chart = getVo2MaxChart0();
      } else {
        chart = getVo2MaxChart1();
      }
      var i = chart.size() - 1;
      while (i >= 0) {
        vo2MaxChart = chart[i] as Array<Number>;
        // System.println(["search", i, vo2MaxChart]);
        if (userAge > vo2MaxChart[0]) {
          // Found age row
          break;
        }
        i--;
      }

      vo2MaxChartKey = userVo2MaxChartKey;
    }
    
    // System.println(["vo2", userVo2MaxChartKey, vo2MaxChart]);

    
    // System.println([userAge, ageAndPerc]);

    if (vo2MaxChart.size() < 5) {
      return 0;
    }

    if (vo2max > vo2MaxChart[4] as Number) {
      // superior
      return 95;
    }

    if (vo2max > vo2MaxChart[3] as Number) {
      // excellent  
      return 80;
    }

    if (vo2max > vo2MaxChart[2] as Number) {
      // Good
      return 60;
    }

    if (vo2max > vo2MaxChart[1] as Number) {
      // Fair
      return 40;
    }    
    // Poor
    return 20;
  }

  // https://www.cyclistshub.com/tools/vo2-max-calculator/
  function getVo2MaxChart0() as Array<Array<Number>> {
    // Female
    return [
        // xx, poor, fair, good, excellent, superior
        // age, <40%, 40%, 60%, 80%, 95%
        // 20-29, <=35, 36-39, 40-43, 44-49, 50+
        [29, 35, 39, 43, 49], // 999],
        [39, 33, 36, 40, 45],
        [49, 31, 34, 38, 44],
        [59, 24, 28, 30, 34],
        [69, 25, 28, 31, 35],
        [79, 23, 26, 29, 35]
      ] as Array<Array<Number>>;       
  }

  function getVo2MaxChart1() as Array<Array<Number>> {
    // male
    return [
        // age, <40%, 40%, 60%, 80%, 95%
        [29, 41, 45, 50, 55], // 999],
        [39, 40, 43, 47, 53],
        [49, 37, 41, 45, 52],
        [59, 34, 37, 42, 49],
        [69, 30, 34, 38, 45],
        [79, 27, 30, 35, 41]
      ] as Array<Array<Number>>; 
  }
}

