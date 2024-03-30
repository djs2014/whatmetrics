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
    HiitMinimal = 1,
    HiitNormal = 2,
  }
  enum HiitSound {
    NoSound = 0,
    StartOnlySound = 1,
    LowNoise = 2,
    LoudNoise = 3,
  }

  hidden var hitMode as HiitMode = HiitDisabled;
  hidden var hitSound as HiitSound = LowNoise;
  hidden var soundEnabled as Boolean = false;

  hidden var hitPerformed as Number = 0;
  hidden var hitStatus as HiitStatus = InActive;
  hidden var hitStartOnPerc as Number = 150;
  hidden var hitStartCountDownSeconds as Number = 5;
  hidden var hitStopOnPerc as Number = 100;
  hidden var hitStopCountDownSeconds as Number = 10;
  hidden var hitCounter as Number = 0;
  hidden var hitElapsedTime as Time.Moment?;
  hidden var hitElapsedRecoveryTime as Time.Moment?;

  hidden var minimalElapsedSeconds as Number = 30;
  hidden var minimalRecoverySeconds as Number = 300;
  hidden var mValidHiitPerformed as Boolean = false;

  hidden var activityPaused as Boolean = false;
  hidden var userPaused as Boolean = false;

  hidden var stoppingCountDownSeconds as Number = 5;
  hidden var stoppingTime as Time.Moment?;

  hidden var calcVo2Max as Boolean = false;
  hidden var playTone as Boolean = true;

  hidden var hitScores as Array<Float> = [] as Array<Float>; //[50.5,30.5,60.4,50.4,60.4]; // @@ TEST
  hidden var hitDurations as Array<Number> = [] as Array<Number>; //[30,31,30,35,40]; // @@ TEST
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
  function setMode(hitMode as HiitMode) as Void {
    self.hitMode = hitMode;
  }
  function setSound(hitSound as HiitSound) as Void {
    self.hitSound = hitSound;
    soundEnabled = (self.hitSound as HiitSound) != NoSound;
  }

  function setStartOnPerc(hitStartOnPerc as Number) as Void {
    self.hitStartOnPerc = hitStartOnPerc;
  }
  function setStopOnPerc(hitStartOnPerc as Number) as Void {
    self.hitStopOnPerc = hitStopOnPerc;
  }
  function setStartCountDownSeconds(hitStartCountDownSeconds as Number) as Void {
    self.hitStartCountDownSeconds = hitStartCountDownSeconds;
  }
  function setStopCountDownSeconds(hitStopCountDownSeconds as Number) as Void {
    self.hitStopCountDownSeconds = hitStopCountDownSeconds;
  }

  function setMinimalElapsedSeconds(minimalElapsedSeconds as Number) as Void {
    self.minimalElapsedSeconds = minimalElapsedSeconds;
  }
  function setMinimalRecoverySeconds(minimalRecoverySeconds as Number) as Void {
    self.minimalRecoverySeconds = minimalRecoverySeconds;
  }

  function isEnabled() as Boolean {
    return (self.hitMode as HiitMode) != HiitDisabled;
  }
  function isMinimal() as Boolean {
    return (self.hitMode as HiitMode) == HiitMinimal;
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
    return hitScores;
  }
  function getHitDurations() as Array<Number> {
    return hitDurations;
  }

  function wasValidHiit() as Boolean {
    return mValidHiitPerformed;
  }

  function compute(info as Activity.Info, percOfTarget as Numeric) as Void {
    if (!isEnabled()) {
      hitElapsedRecoveryTime = null;
      hitElapsedTime = null;
      return;
    }

    calcVo2Max = (hitStatus as HiitStatus) == Active;
    updateMetrics(info);
    updateRecoveryTime();
    if (activityPaused) {
      hitStatus = InActive;
      hitCounter = 0;
      hitElapsedRecoveryTime = null;
      hitElapsedTime = null;
      playTone = soundEnabled;
      return;
    }
    //System.println(percOfTarget);

    switch (hitStatus) {
      case InActive:
        System.println("InActive");
        if (percOfTarget >= hitStartOnPerc) {
          // Start warming up for x seconds
          hitStatus = WarmingUp;
          hitCounter = hitStartCountDownSeconds;
          playTone = soundEnabled;
        }
        break;
      case WarmingUp:
        System.println("Warming up");
        hitCounter = hitCounter - 1;
        hitAttentionWarmingUp(playTone);
        mValidHiitPerformed = false;

        if (percOfTarget < hitStartOnPerc) {
          // Stop warming up
          hitStatus = InActive;
          hitCounter = 0;
        } else {
          if (hitCounter == 0) {
            // End of warming up, start Hiit
            resetAveragePower();
            hitStatus = Active;
            hitElapsedRecoveryTime = null;
            currentDuration = 0;
            currentScore = 0.0f;
            hitElapsedTime = Time.now();
            hitAttentionStart();
          }
        }
        break;
      case CoolingDown:
        System.println("Cooling down");
        hitAttentionCoolingdown(playTone);
        hitCounter = hitCounter - 1;

        if (percOfTarget >= hitStopOnPerc) {
          // Stop cooling down
          hitStatus = Active;
          hitCounter = 0;
        } else {
          if (hitCounter == 0) {
            hitStatus = InActive;

            // currentDuration = actual hiit seconds just before cooling down
            if (currentDuration >= minimalElapsedSeconds) {
              hitAttentionStop();
              // Proper Hiit :-)
              hitPerformed = hitPerformed + 1;
              hitElapsedRecoveryTime = Time.now();
              hitScores.add(currentScore);
              hitDurations.add(currentDuration);
            } else {
              // No proper Hiit (no sound)
              hitStatus = InActive;
              hitCounter = 0;
              hitElapsedRecoveryTime = null;
              currentScore = 0.0f;
              currentDuration = 0;
            }
            hitElapsedTime = null;
          }
        }
        break;
      case Active:
        System.println("Active");

        mValidHiitPerformed = getElapsedSeconds() >= minimalElapsedSeconds;
        if (percOfTarget < hitStopOnPerc) {
          hitStatus = CoolingDown;
          hitCounter = hitStopCountDownSeconds;
          hitAttentionWarn();
          currentDuration = getElapsedSeconds();
          // only sound when proper Hiit
          playTone = soundEnabled && mValidHiitPerformed;
          currentScore = getVo2Max();
        } else {
          addAveragePower(info);
        }
        break;
    }
  }

  hidden function resetAveragePower() as Void {
    powerTicks = 0;
    avgPowerPerSec = 0.0d;
  }
  hidden function addAveragePower(info as Activity.Info) as Void {
    var power = getActivityValue(info, :currentPower, 0) as Number;
    // [ avg' * (n-1) + x ] / n
    powerTicks = powerTicks + 1;
    avgPowerPerSec = (avgPowerPerSec * (powerTicks - 1) + power) / powerTicks.toDouble();
    System.println(Lang.format("p $1$ ticks $2$ avg $3$", [power, powerTicks, avgPowerPerSec]));
  }

  hidden function updateRecoveryTime() as Void {
    if (hitElapsedRecoveryTime == null) {
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
      hitElapsedRecoveryTime = null;
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
    hitScores = [] as Array<Float>;
    hitDurations = [] as Array<Number>;
    hitPerformed = 0;
    currentDuration = 0;
    currentScore = 0.0f;
    hitCounter = 0;
    hitElapsedRecoveryTime = null;
    hitElapsedTime = null;
    resetAveragePower();
  }

  hidden function hitAttentionWarmingUp(playTone as Boolean) as Void {
    if (Attention has :playTone && soundEnabled && playTone) {
      if (Attention has :ToneProfile) {
        var toneProfileBeeps = [new Attention.ToneProfile(1500, 50)] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      } else {
        Attention.playTone(Attention.TONE_LOUD_BEEP);
      }
    }
  }

  hidden function hitAttentionCoolingdown(playTone as Boolean) as Void {
    if (Attention has :playTone && soundEnabled && playTone && hitSound != StartOnlySound) {
      if (Attention has :ToneProfile && hitSound == LowNoise) {
        var toneProfileBeeps = [new Attention.ToneProfile(1000, 50)] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      } else {
        Attention.playTone(Attention.TONE_LOUD_BEEP);
      }
    }
  }

  hidden function hitAttentionWarn() as Void {
    if (Attention has :playTone && soundEnabled) {
      if (Attention has :ToneProfile) {
        var toneProfileBeeps =
          [new Attention.ToneProfile(1000, 40), new Attention.ToneProfile(1500, 100)] as
          Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      }
    }
  }

  hidden function hitAttentionStart() as Void {
    if (Attention has :playTone && soundEnabled) {
      if (Attention has :ToneProfile && hitSound == LowNoise) {
        var toneProfileBeeps = [new Attention.ToneProfile(1100, 150)] as Lang.Array<Attention.ToneProfile>;
        Attention.playTone({ :toneProfile => toneProfileBeeps });
      } else {
        Attention.playTone(Attention.TONE_ALERT_HI);
      }
    }
  }

  hidden function hitAttentionStop() as Void {
    if (Attention has :playTone && soundEnabled && hitSound != StartOnlySound) {
      if (Attention has :ToneProfile && hitSound == LowNoise) {
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
    if (hitElapsedTime == null) {
      return 0;
    }
    return Time.now().value() - (hitElapsedTime as Time.Moment).value();
  }

  // Count down to 0
  function getRecoveryElapsedSeconds() as Number {
    // @@ Stop if greater than 6 minutes , Setting
    if (hitElapsedRecoveryTime == null) {
      return 0;
    }
    var seconds = Time.now().value() - (hitElapsedRecoveryTime as Time.Moment).value();
    var leftOver = minimalRecoverySeconds - seconds;
    if (leftOver < 0) {
      hitElapsedRecoveryTime = null;
      return 0;
    }
    return leftOver;
  }

  function getNumberOfHits() as Number {
    return hitPerformed;
  }

  function getCounter() as Number {
    return hitCounter;
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
