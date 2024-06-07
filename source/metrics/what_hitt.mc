import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.System;
import Toybox.Attention;
import Toybox.Time;

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

  hidden var hiitScores as Array<Float> = [] as Array<Float>; //[50.5,30.5,60.4,50.4,60.4]; // @@ TEST
  hidden var hiitDurations as Array<Number> = [] as Array<Number>; //[30,31,30,35,40]; // @@ TEST
  hidden var currentDuration as Number = 0;
  hidden var currentScore as Float = 0.0f;

  hidden var currentTimerState as Number = Activity.TIMER_STATE_OFF;
  hidden var userWeightKg as Float = 0.0f;
  hidden var powerTicks as Number = 0;
  hidden var avgPowerPerSec as Double = 0.0d;

  function initialize() {}

  function updateProfile() as Void {
    var profile = UserProfile.getProfile();
    if (profile.weight != null) {
      var weight = profile.weight as Number;
      userWeightKg = weight / 1000.0;
    }
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
    if (hiitMode == HiitAlwaysOn) {
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

  function getHitScores() as Array<Float> {
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
            currentScore = 0.0f;
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
              currentScore = 0.0f;
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

  hidden function stopping() as Boolean {
    return activityPaused || userPaused;
  }

  hidden function reset() as Void {
    hiitScores = [] as Array<Float>;
    hiitDurations = [] as Array<Number>;
    hiitPerformed = 0;
    currentDuration = 0;
    currentScore = 0.0f;
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

  function getNumberOfHits() as Number {
    return hiitPerformed;
  }

  function getCounter() as Number {
    return hiitCounter;
  }

  // vo2max = ((6min pow er * 10.8) / weight) + 7
  // https://www.michael-konczer.com/en/training/calculators/calculate-vo2max
  function getVo2Max() as Float {
    if (userWeightKg == 0.0f) {
      return 0.0f;
    }
    var pp6min = avgPowerPerSec.toNumber();
    return (pp6min * 10.8) / userWeightKg + 7;
  }
}
