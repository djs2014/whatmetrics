import Toybox.Activity;
import Toybox.Lang;
import Toybox.System;
import Toybox.Math;
import Toybox.Time;
import Toybox.AntPlus;

class WhatMetrics {
  hidden var a_info as Activity.Info?;
  // @@ hidden var cadence_target as Number = 30;
  // @@ targets ?? in view

  // grade
  hidden var mCurrentGrade as Double = 0.0d;
  hidden var gradeWindowSize as Number = 4;
  hidden var arrGrade as Array<Float> = [] as Array<Float>;
  hidden var previousAltitude as Float = 0.0f;
  hidden var previousDistance as Float = 0.0f;
  hidden var previousRise as Float = 0.0f;
  // bearing
  hidden var previousTrack as Float = 0.0f;
  // power
  hidden var mCurrentPowerPerX as Number = 0;
  hidden var mPowerPerSec as Number = 3;
  hidden var mPowerDataPerSec as Array<Number> = [] as Array<Number>;
  hidden var mPowerBalance as PowerBalance? = null;
  hidden var userWeightKg as Float = 0.0f;

  // heartrate
  hidden var mHrZones as Lang.Array<Lang.Number> = [] as Lang.Array<Lang.Number>;
  function initialize() {}

  function initPowerBalance() as Void {
    if (mPowerBalance == null) {
      mPowerBalance = new PowerBalance();
    }
  }

  function initWeight() as Void {
    var profile = UserProfile.getProfile();
    userWeightKg = 0.0f;
    if (profile.weight == null) {
      return;
    }
    var weight = profile.weight as Number;
    userWeightKg = weight / 1000.0;
  }

  function initHrZones(zones as Lang.Array<Lang.Number>) as Void {
    mHrZones = zones;
  }

  function setPowerPerSec(seconds as Number) as Void {
    mPowerPerSec = seconds;
  }
  function setGradeWindowSize(size as Number) as Void {
    gradeWindowSize = size;
  }
  // cadence, rpm,
  function getCadence() as Number {
    return getActivityValue(a_info, :currentCadence, 0) as Number;
  }
  function getAverageCadence() as Number {
    return getActivityValue(a_info, :averageCadence, 0) as Number;
  }
  function getMaxCadence() as Number {
    return getActivityValue(a_info, :maxCadence, 0) as Number;
  }

  // calories, kcal (total)
  function getCalories() as Number {
    return getActivityValue(a_info, :calories, 0) as Number;
  }
  // energy kcal/min
  function getEnergyExpenditure() as Number {
    return getActivityValue(a_info, :energyExpenditure, 0) as Number;
  }

  // altitude, meters
  function getAltitude() as Float {
    return getActivityValue(a_info, :altitude, 0.0f) as Float;
  }
  function getTotalAscent() as Float {
    return getActivityValue(a_info, :totalAscent, 0.0f) as Float;
  }
  function getTotalDescent() as Float {
    return getActivityValue(a_info, :totalDescent, 0.0f) as Float;
  }

  // heartrate, bpm
  function getHeartRate() as Number {
    return getActivityValue(a_info, :currentHeartRate, 0) as Number;
  }
  function getAverageHeartRate() as Number {
    return getActivityValue(a_info, :averageHeartRate, 0) as Number;
  }
  function getMaxHeartRate() as Number {
    return getActivityValue(a_info, :maxHeartRate, 0) as Number;
  }
  function getHeartRateZone() as Number {
    if (mHrZones.size() == 0) {
      return 0;
    }
    var heartRate = getHeartRate();
    if (heartRate < mHrZones[0]) {
      return 0;
    }
    for (var idx = 1; idx < mHrZones.size(); idx++) {
      if (heartRate <= mHrZones[idx]) {
        return idx;
      }
    }
    return mHrZones.size();
  }

  // distance, meters
  hidden function getElapsedDistance() as Float {
    return getActivityValue(a_info, :elapsedDistance, 0.0f) as Float;
  }

  function getGrade() as Double {
    return mCurrentGrade;
  }
  // debug
  function getGradeArray() as Array<Float> {
    return arrGrade;
  }

  // Bearing in degrees
  function getBearing() as Number {
    var track = getActivityValue(a_info, :track, 0.0f) as Float;
    if (track == 0.0f) {
      track = getActivityValue(a_info, :currentHeading, 0.0f) as Float;
    }
    if (track == 0.0f) {
      track = previousTrack;
    } else {
      previousTrack = track;
    }
    return rad2deg(track).toNumber();
  }

  // speed, meter/s,
  function getSpeed() as Float {
    return getActivityValue(a_info, :currentSpeed, 0.0f) as Float;
  }
  function getAverageSpeed() as Float {
    return getActivityValue(a_info, :averageSpeed, 0.0f) as Float;
  }
  function getMaxSpeed() as Float {
    return getActivityValue(a_info, :maxSpeed, 0.0f) as Float;
  }
  // power interval sec
  function getPowerPerSec() as Number {
    return mPowerPerSec;
  }
  // power watts / x seconds
  function getPower() as Number {
    return mCurrentPowerPerX;
  }
  function getAveragePower() as Number {
    return getActivityValue(a_info, :averagePower, 0) as Number;
  }
  function getMaxPower() as Number {
    return getActivityValue(a_info, :maxPower, 0) as Number;
  }
  function getPowerPerWeight() as Float {
    if (userWeightKg == 0) {
      return 0.0f;
    }
    return getPower() / userWeightKg.toFloat();
  }

  function getPowerBalanceLeft() as Number {
    if (mPowerBalance != null) {
      return (mPowerBalance as PowerBalance).getLeft();
    }
    return 0;
  }
  function getAveragePowerBalanceLeft() as Double {
    if (mPowerBalance != null) {
      return (mPowerBalance as PowerBalance).getAverageLeft();
    }
    return 0.0d;
  }

  // time of day, timer, elapsed time, date dd-month
  // elapsed time in millisec
  function getElapsedTime() as Number {
    return getActivityValue(a_info, :elapsedTime, 0) as Number;
  }
  // current timer value in millisec
  function getTimerTime() as Number {
    return getActivityValue(a_info, :timerTime, 0) as Number;
  }
  // start time of activity
  function getStartTime() as Time.Moment {
    return getActivityValue(a_info, :startTime, 0) as Time.Moment;
  }

  // called per second
  function compute(info as Activity.Info) as Void {
    previousAltitude = getAltitude();
    previousDistance = getElapsedDistance();

    a_info = info;

    calculateMetrics();

    if (mPowerBalance != null) {
      (mPowerBalance as PowerBalance).compute(getPower());
    }
  }

  hidden function calculateMetrics() as Void {
    mCurrentGrade = calculateGrade();
    mCurrentPowerPerX = calculatePower();
  }

  hidden function calculatePower() as Number {
    var power = getActivityValue(a_info, :currentPower, 0) as Number;

    if (mPowerDataPerSec.size() >= mPowerPerSec) {
      mPowerDataPerSec = mPowerDataPerSec.slice(1, mPowerPerSec);
    }
    mPowerDataPerSec.add(power);

    if (mPowerDataPerSec.size() == 0) {
      return 0;
    }
    return Math.mean(mPowerDataPerSec as Array<Number>).toNumber();
  }

  hidden function calculateGrade() as Double {
    var altitude = getAltitude();
    var distance = getElapsedDistance();
    var rise = previousAltitude - altitude;
    var run = previousDistance - distance;

    if (run != 0.0 and (rise < -0.01 or rise > 0.01)) {
      var grade = 0.0f;
      grade = (rise.toFloat() / run.toFloat()) * 100.0;

      if (previousRise < 0 and rise > 0 or (previousRise > 0 and rise < 0)) {
        arrGrade = [] as Array<Float>;
      }
      arrGrade.add(grade);
      if (arrGrade.size() > gradeWindowSize) {
        arrGrade = arrGrade.slice(1, null);
      }
      previousRise = rise;
    } else if (rise >= -0.01 and rise <= 0.01) {
      previousRise = rise;
      arrGrade = [] as Array<Float>;
      return 0.0d;
    }

    if (arrGrade.size() == 0) {
      return 0.0d;
    }
    return Math.mean(arrGrade as Array<Float>);
  }
}

class PowerBalance {
  hidden var bikePower as AntPlus.BikePower;
  hidden var listener as ABikePowerListener;
  hidden var mPowerBalanceLeft as Number = 0;
  hidden var ticks as Number = 0;
  hidden var avgPowerBalanceLeft as Double = 0.0d;
  function initialize() {
    listener = new ABikePowerListener(self.weak(), :onPedalPowerBalanceUpdate);
    bikePower = new AntPlus.BikePower(listener);
  }

  function getLeft() as Number {
    return mPowerBalanceLeft;
  }
  function getAverageLeft() as Double {
    return avgPowerBalanceLeft;
  }

  function compute(power as Number) as Void {
    if (power > 0 && mPowerBalanceLeft != null && mPowerBalanceLeft > 0) {
      ticks = ticks + 1;
      var a = 1 / ticks.toDouble();
      var b = 1 - a;
      avgPowerBalanceLeft = a * mPowerBalanceLeft + b * avgPowerBalanceLeft;
    }
  }
  function onPedalPowerBalanceUpdate(pedalPowerPercent as Lang.Number, rightPedalIndicator as Lang.Boolean) as Void {
    if (rightPedalIndicator) {
      mPowerBalanceLeft = 100 - pedalPowerPercent;
    } else {
      mPowerBalanceLeft = pedalPowerPercent;
    }
  }
}
