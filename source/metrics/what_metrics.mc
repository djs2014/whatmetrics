import Toybox.Activity;
import Toybox.Lang;
import Toybox.System;
import Toybox.Math;
import Toybox.Time;
import Toybox.AntPlus;

class WhatMetrics {
  hidden var a_info as Activity.Info?;
  hidden var mPaused as Boolean = true;
 
  // bearing
  hidden var previousTrack as Float = 0.0f;
  // power
  hidden var mCurrentPowerPerX as Number = 0;
  hidden var mPowerPerSec as Number = 3;
  hidden var mPowerDataPerSec as Array<Number> = [] as Array<Number>;
  hidden var mPowerBalance as PowerBalance? = null;

  hidden var mUserWeightKg as Float = 0.0f;
  hidden var mUserFTP as Number = 0;

  // detect if l/r power is not 0 for x seconds
  hidden var mPowerDualSecFallback as Number = 0;
  hidden var mPowerTimesTwo as Boolean = false;
  hidden var mFailingPowerPedalsCounter as Number = 0;
  hidden var mHasFailingDualpower as Boolean = false;

  // heartrate
  hidden var mHrZones as Lang.Array<Lang.Number> =
    [] as Lang.Array<Lang.Number>;

  // shifting - battery status
  hidden var mShifting as ShiftListener? = null;

  // pressure - history
  hidden var mPressureTicks as Number = 0;
  hidden var mAveragePressure as Float = 0.0f;

  function initialize() {}

  // function reset() as Void {
  //   resetAverageNP();
  // }
  function initPowerBalance(
    powerDualSecFallback as Number,
    powerTimesTwo as Boolean
  ) as Void {
    if (mPowerBalance == null) {
      mPowerBalance = new PowerBalance();
    }
    mPowerDualSecFallback = powerDualSecFallback;
    mHasFailingDualpower = false;
    mPowerTimesTwo = powerTimesTwo;
  }
  function initShiftListener() as Void {
    if (mShifting == null) {
      mShifting = new ShiftListener();
    }
  }
  function initWeight() as Void {
    var profile = UserProfile.getProfile();
    mUserWeightKg = 0.0f;
    if (profile.weight == null) {
      return;
    }
    var weight = profile.weight as Number;
    mUserWeightKg = weight / 1000.0;
  }

  function initHrZones(zones as Lang.Array<Lang.Number>) as Void {
    mHrZones = zones;
  }

  // @@TODO initPwrZones

  function setFTP(ftp as Number) as Void {
    mUserFTP = ftp;
  }

  function setPowerPerSec(seconds as Number) as Void {
    mPowerPerSec = seconds;
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

  // pressure hPa
  function getAmbientPressure() as Float {
    return (getActivityValue(a_info, :ambientPressure, 0.0f) as Float) / 100.0;
  }
  function getMeanSeaLevelPressure() as Float {
    return (
      (getActivityValue(a_info, :meanSeaLevelPressure, 0.0f) as Float) / 100.0
    );
  }

  // -1 down, 0 stable, 1 up
  function getPressureTrend() as Number {
    var pressure = getActivityValue(a_info, :ambientPressure, 0.0f) as Float;
    if (pressure == 0.0f) {
      return 0;
    }

    // Calc trend
    var trend = 0;
    if (pressure < mAveragePressure) {
      trend = -1;
    } else if (pressure > mAveragePressure) {
      trend = 1;
    }

    // Add current to average
    //Rolling average ( avg' * (n-1) + x ) / n
    mPressureTicks = mPressureTicks + 1;
    mAveragePressure =
      (mAveragePressure * (mPressureTicks - 1) + pressure) /
      mPressureTicks.toFloat();
    // System.println(Lang.format("p $1$ ticks $2$ avg $3$", [pressure, mPressureTicks, mAveragePressure]));

    return trend;
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
  function getHeartRateZone(showAverage as Boolean) as Number {
    if (mHrZones.size() == 0) {
      return 0;
    }
    var heartRate = 0;
    if (showAverage) {
      heartRate = getAverageHeartRate();
    } else {
      heartRate = getHeartRate();
    }
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
  function getMaxHeartRateZone() as Number {
    return mHrZones.size() - 1; // Zone 0 to 5
  }

  // distance, meters
  function getElapsedDistance() as Float {
    return getActivityValue(a_info, :elapsedDistance, 0.0f) as Float;
  }
  function getDistanceToNextPoint() as Float {
    return getActivityValue(a_info, :distanceToNextPoint, 0.0f) as Float;
  }
  function getDistanceToDestination() as Float {
    return getActivityValue(a_info, :distanceToDestination, 0.0f) as Float;
  }

  // size of chainring
  function getFrontDerailleurSize() as Number {
    return getActivityValue(a_info, :frontDerailleurSize, 0) as Number;
  }
  function getRearDerailleurSize() as Number {
    return getActivityValue(a_info, :rearDerailleurSize, 0) as Number;
  }
  // index of chainring
  function getFrontDerailleurIndex() as Number {
    return getActivityValue(a_info, :frontDerailleurIndex, 0) as Number;
  }
  function getRearDerailleurIndex() as Number {
    return getActivityValue(a_info, :rearDerailleurIndex, 0) as Number;
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
    if (mHasFailingDualpower || mPowerTimesTwo) {
      // Compensate for 1 failing pedal
      return mCurrentPowerPerX * 2;
    }
    return mCurrentPowerPerX;
  }
  function getAveragePower() as Number {
    return getActivityValue(a_info, :averagePower, 0) as Number;
  }
  function getMaxPower() as Number {
    return getActivityValue(a_info, :maxPower, 0) as Number;
  }
  function getPowerPerWeight() as Float {
    if (mUserWeightKg == 0) {
      return 0.0f;
    }
    return getPower() / mUserWeightKg.toFloat();
  }
  function getAveragePowerPerWeight() as Float {
    if (mUserWeightKg == 0) {
      return 0.0f;
    }
    return getAveragePower() / mUserWeightKg.toFloat();
  }

  function getNormalizedPower() as Number {
    return mCurrentNP;
  }

  function getUserFTP() as Number {
    return mUserFTP;
  }

  function getIntensityFactor() as Float {
    if (mUserFTP == 0) {
      return 0.0f;
    }
    return getNormalizedPower() / mUserFTP.toFloat();
  }

  function getTrainingStressScore() as Float {
    if (mUserFTP == 0) {
      return 0.0f;
    }
    // TSS = (sec × NP × IF) / (FTP × 3600) × 100
    var seconds = getTimerTime() / 1000.0;
    var fraction = mUserFTP.toFloat() * 3600.0f;
    if (fraction == 0) {
      return 0.0f;
    }
    return (
      ((seconds * getNormalizedPower() * getIntensityFactor()) / fraction) *
      100.0f
    );
  }

  // % power balance left
  function getPowerBalanceLeft() as Number {
    if (mPowerBalance != null) {
      return (mPowerBalance as PowerBalance).getLeft();
    }
    return 0;
  }
  function getAveragePowerBalanceLeft() as Float {
    if (mPowerBalance != null) {
      return (mPowerBalance as PowerBalance).getAverageLeft();
    }
    return 0.0f;
  }

  // one of the power pedals is not working .. @@ experimental
  function getHasFailingDualpower() as Boolean {
    return mHasFailingDualpower;
  }

  function getPowerBatteryLevel() as Number {
    if (mPowerBalance != null) {
      return (mPowerBalance as PowerBalance).getBatteryLevel();
    }
    return -1;
  }
  function getPowerOperatingTimeInSeconds() as Number {
    if (mPowerBalance != null) {
      return (mPowerBalance as PowerBalance).getOperatingTimeInSeconds();
    }
    return -1;
  }
  function getPowerBatteryVoltage() as Float {
    if (mPowerBalance != null) {
      return (mPowerBalance as PowerBalance).getBatteryVoltage();
    }
    return -1.0f;
  }

  // shifting @@ TEST
  function getShiftingBatteryLevel() as Number {
    initShiftListener();
    if (mShifting != null) {
      return (mShifting as ShiftListener).getBatteryLevel();
    }
    return -1;
  }

  // time of day, timer, elapsed time, date dd-month
  // elapsed time in millisec
  function getElapsedTime() as Number {
    return $.getActivityValue(a_info, :elapsedTime, 0) as Number;
  }
  // current timer value in millisec
  function getTimerTime() as Number {
    return $.getActivityValue(a_info, :timerTime, 0) as Number;
  }
  // start time of activity
  function getStartTime() as Time.Moment {
    return $.getActivityValue(a_info, :startTime, 0) as Time.Moment;
  }

  // get estimated duration to destination in seconds (targetDistance in meters)
  function getEstimatedDurationToDestination(
    targetDistance as Number,
    useRoute as Boolean
  ) as Number {
    var averageSpeed = getAverageSpeed();
    if (averageSpeed == 0) {
      return 0;
    }
    // No target and not using route
    if (targetDistance == 0 && !useRoute) {
      return 0;
    }

    var distanceRemaining = targetDistance - getElapsedDistance();
    var dd = getDistanceToDestination();

    //System.println([distanceRemaining, dd, useRoute, averageSpeed]);

    if (useRoute && dd > 0) {
      distanceRemaining = dd;
    }

    return (distanceRemaining / averageSpeed).toNumber();
  }

  // called per second
  function compute(info as Activity.Info) as Void {
    var currentState = $.getActivityValue(
      info,
      :timerState,
      Activity.TIMER_STATE_OFF
    );

    mPaused =
      currentState == Activity.TIMER_STATE_PAUSED or
      currentState == Activity.TIMER_STATE_OFF;
    if (currentState == Activity.TIMER_STATE_OFF) {
      resetAverageNP();
    }

    a_info = info;

    var power = getActivityValue(a_info, :currentPower, 0) as Number;

    checkForFalingDualPower();
    mCurrentPowerPerX = calculatePower(power);

    // TODO NP calc also when paused?
    if (!mPaused) {
      mCurrentNP = calculateNormalizedPower(calculatePower30(power));
    }

    if (mPowerBalance != null) {
      (mPowerBalance as PowerBalance).compute(getPower());
    }
  }

  hidden function calculatePower(power as Number) as Number {
    if (mPowerDataPerSec.size() >= mPowerPerSec) {
      mPowerDataPerSec = mPowerDataPerSec.slice(1, mPowerPerSec);
    }
    mPowerDataPerSec.add(power);

    if (mPowerDataPerSec.size() == 0) {
      return 0;
    }
    return Math.mean(mPowerDataPerSec as Array<Numeric>).toNumber();
  }

  // Normalized power
  hidden var mPowerDataPer30Sec as Array<Number> = [] as Array<Number>;
  hidden var mCurrentNP as Number = 0;

  // Low-memory running registers for global NP
  hidden var mSumPowerToFourth as Double = 0.0d;
  hidden var mTotalNPSamples as Long = 0l;

  hidden function calculatePower30(power as Number) as Number {
    if (mPowerDataPer30Sec.size() >= 30) {
      mPowerDataPer30Sec = mPowerDataPer30Sec.slice(1, 30);
    }
    mPowerDataPer30Sec.add(power);

    if (mPowerDataPer30Sec.size() == 0) {
      return 0;
    }
    return Math.mean(mPowerDataPer30Sec as Array<Numeric>).toNumber();
  }

  hidden function calculateNormalizedPower(PowerPer30 as Number) as Number {
    // Only start accumulating data once our initial 30-second buffer fills up
    if (mPowerDataPer30Sec.size() < 30) {
      return 0;
    }

    // Add the current 30s rolling average (raised to the 4th power) to our lifetime total
    mSumPowerToFourth += Math.pow(PowerPer30, 4);
    mTotalNPSamples++; // Track total seconds spent calculating NP

    // Calculate the mean over the ENTIRE ride duration
    var globalAvg = mSumPowerToFourth / mTotalNPSamples;

    // Return the 4th root
    return Math.pow(globalAvg, 0.25).toNumber();
  }

  hidden function checkForFalingDualPower() as Void {
    if (mPowerBalance == null) {
      return;
    }
    if (mPowerDualSecFallback == 0) {
      return;
    }

    var pedal = (mPowerBalance as PowerBalance).getActivePowerPedals();

    if (pedal == "L" || pedal == "R" || pedal == "") {
      mFailingPowerPedalsCounter = mFailingPowerPedalsCounter + 1;
    } else {
      mFailingPowerPedalsCounter = 0;
    }
    mHasFailingDualpower = mFailingPowerPedalsCounter > mPowerDualSecFallback;
    // System.println(
    //   "FailingPowerPedalsCounter " + mFailingPowerPedalsCounter + " mHasFailingDualpower " + mHasFailingDualpower
    // );
  }

  hidden function resetAverageNP() as Void {
    mCurrentNP = 0;
  }



}

class ShiftListener {
  hidden var shifting as AntPlus.Shifting;
  hidden var listener as AShiftingListener;
  hidden var batteryLevel as Number = -1;

  hidden var operatingTimeInSeconds as Number;
  hidden var batteryVoltage as Float;

  function initialize() {
    listener = new AShiftingListener(self, :onBatteryStatusUpdate);
    shifting = new AntPlus.Shifting(listener);
    operatingTimeInSeconds = -1;
    batteryVoltage = -1.0f;
  }

  function getBatteryLevel() as Number {
    return batteryLevel;
  }

  function getOperatingTimeInSeconds() as Number {
    return operatingTimeInSeconds as Number;
  }
  function getBatteryVoltage() as Float {
    return batteryVoltage as Float;
  }

  function onBatteryStatusUpdate(
    batteryStatus as AntPlus.BatteryStatusValue,
    operatingTime as Number,
    abatteryVoltage as Float
  ) as Void {
    batteryLevel = -1;
    if (batteryStatus == AntPlus.BATT_STATUS_NEW) {
      batteryLevel = 5;
    } else if (batteryStatus == AntPlus.BATT_STATUS_GOOD) {
      batteryLevel = 4;
    } else if (batteryStatus == AntPlus.BATT_STATUS_OK) {
      batteryLevel = 3;
    } else if (batteryStatus == AntPlus.BATT_STATUS_LOW) {
      batteryLevel = 2;
    } else if (batteryStatus == AntPlus.BATT_STATUS_CRITICAL) {
      batteryLevel = 1;
    } else if (batteryStatus == AntPlus.BATT_STATUS_INVALID) {
      batteryLevel = 0;
    }

    if (operatingTime == null) {
      operatingTimeInSeconds = -1;
    } else {
      operatingTimeInSeconds = operatingTime;
    }

    if (abatteryVoltage == null) {
      batteryVoltage = -1.0f;
    } else {
      batteryVoltage = abatteryVoltage;
    }
  }
}

class PowerBalance {
  hidden var bikePower as AntPlus.BikePower;
  hidden var listener as ABikePowerListener;
  hidden var mPowerBalanceLeft as Number = 0;
  hidden var ticks as Number = 0;
  hidden var avgPowerBalanceLeft as Float = 0.0f;
  hidden var batteryLevel as Number = -1;

  hidden var operatingTimeInSeconds as Number;
  hidden var batteryVoltage as Float;

  function initialize() {
    listener = new ABikePowerListener(
      self,
      :onPedalPowerBalanceUpdate,
      :onBatteryStatusUpdate
    );
    bikePower = new AntPlus.BikePower(listener);
    operatingTimeInSeconds = -1;
    batteryVoltage = -1.0f;
  }

  function getLeft() as Number {
    return mPowerBalanceLeft;
  }
  function getAverageLeft() as Float {
    return avgPowerBalanceLeft;
  }

  function getBatteryLevel() as Number {
    return batteryLevel;
  }

  function getOperatingTimeInSeconds() as Number {
    return operatingTimeInSeconds as Number;
  }
  function getBatteryVoltage() as Float {
    return batteryVoltage as Float;
  }

  function getActivePowerPedals() as String {
    var balance = bikePower.getPedalPowerBalance();
    if (balance == null) {
      // can be null!
      return "";
    }
    var pedalPowerPercent = balance.pedalPowerPercent;
    var rightPedalIndicator = balance.rightPedalIndicator;

    if (pedalPowerPercent == null || rightPedalIndicator == null) {
      return "";
    } else if (pedalPowerPercent == 100 && rightPedalIndicator) {
      return "R";
    } else if (pedalPowerPercent == 100 && !rightPedalIndicator) {
      return "L";
    }
    return "LR";
  }

  function compute(power as Number) as Void {
    if (power > 0 && mPowerBalanceLeft != null && mPowerBalanceLeft > 0) {
      ticks = ticks + 1;
      var a = 1 / ticks.toFloat();
      var b = 1 - a;
      avgPowerBalanceLeft = a * mPowerBalanceLeft + b * avgPowerBalanceLeft;
    }
  }
  function onPedalPowerBalanceUpdate(
    pedalPowerPercent as Lang.Number,
    rightPedalIndicator as Lang.Boolean
  ) as Void {
    if (rightPedalIndicator) {
      mPowerBalanceLeft = 100 - pedalPowerPercent;
    } else {
      mPowerBalanceLeft = pedalPowerPercent;
    }
  }

  function onBatteryStatusUpdate(
    batteryStatus as AntPlus.BatteryStatusValue,
    operatingTime as Number,
    abatteryVoltage as Float
  ) as Void {
    batteryLevel = -1;
    if (batteryStatus == AntPlus.BATT_STATUS_NEW) {
      batteryLevel = 5;
    } else if (batteryStatus == AntPlus.BATT_STATUS_GOOD) {
      batteryLevel = 4;
    } else if (batteryStatus == AntPlus.BATT_STATUS_OK) {
      batteryLevel = 3;
    } else if (batteryStatus == AntPlus.BATT_STATUS_LOW) {
      batteryLevel = 2;
    } else if (batteryStatus == AntPlus.BATT_STATUS_CRITICAL) {
      batteryLevel = 1;
    } else if (batteryStatus == AntPlus.BATT_STATUS_INVALID) {
      batteryLevel = 0;
    }

    if (operatingTime == null) {
      operatingTimeInSeconds = -1;
    } else {
      operatingTimeInSeconds = operatingTime;
    }

    if (abatteryVoltage == null) {
      batteryVoltage = -1.0f;
    } else {
      batteryVoltage = abatteryVoltage;
    }
  }
}
