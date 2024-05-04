import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Storage;
using Toybox.Time;
using Toybox.Time.Gregorian;

class whatmetricsView extends WatchUi.DataField {
  hidden var mFieldSize as String;
  hidden var mYoffsetFix as Number = 0;

  hidden var mDebug as Boolean = true;
  hidden var mPaused as Boolean = true;
  hidden var mActivityStartCountdown as Number = 0;
  hidden var mPowerFallbackCountdown as Number = 0;
  hidden var mCadenceFallbackCountdown as Number = 0;

  // [[w,h],[w,h],[w,h]]
  hidden var mGrid as Array<Array<Array<Number> > > = [] as Array<Array<Array<Number> > >;
  hidden var mFontColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mReverseColor as Boolean = false;
  hidden var mDecimalsColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mDecimalsColorDay as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mDecimalsColorNight as Graphics.ColorType = Graphics.COLOR_WHITE;
  hidden var mUnitsColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mUnitsColorDay as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mUnitsColorNight as Graphics.ColorType = Graphics.COLOR_WHITE;
  hidden var mIconColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mIconColorDay as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mIconColorNight as Graphics.ColorType = Graphics.COLOR_WHITE;
  hidden var mFontsNumbers as Array = [
    Graphics.FONT_XTINY,
    Graphics.FONT_TINY,
    Graphics.FONT_SYSTEM_SMALL,
    Graphics.FONT_NUMBER_MILD,
    Graphics.FONT_NUMBER_HOT,
    Graphics.FONT_NUMBER_THAI_HOT,
  ];
  hidden var mFonts as Array = [
    Graphics.FONT_XTINY,
    Graphics.FONT_TINY,
    Graphics.FONT_SYSTEM_SMALL,
    Graphics.FONT_SYSTEM_MEDIUM,
    Graphics.FONT_SYSTEM_LARGE,
  ];

  hidden var mHiitt as WhatHiitt;
  hidden var mMetrics as WhatMetrics;
  hidden var mFields as Array<Number> = [] as Array<Number>;
  hidden var mZenMode as ZenMode = ZMOff;
  hidden var mDisplaySize as String = "s";

  // hidden var mGrade as Double = 0.0d;
  function initialize() {
    DataField.initialize();
    mFieldSize = "?x?";

    mHiitt = $.getHiitt() as WhatHiitt;
    mMetrics = $.getWhatMetrics() as WhatMetrics;

    checkFeatures();
    if ($.gCreateColors) {
      mDecimalsColorDay = Graphics.createColor(180, 50, 50, 50);
      mDecimalsColorNight = Graphics.createColor(180, 150, 150, 150);

      mUnitsColorDay = Graphics.createColor(180, 100, 100, 100);
      mUnitsColorNight = Graphics.createColor(180, 220, 220, 220);

      mIconColorDay = Graphics.createColor(255, 220, 220, 220);
      mIconColorNight = Graphics.createColor(255, 100, 100, 100);
    }
  }

  function onLayout(dc as Dc) as Void {
    var h = dc.getHeight();
    var w = dc.getWidth();
    mFieldSize = Lang.format("$1$x$2$", [w, h]);

    mDisplaySize = $.getDisplaySize(w, h);
    if (mDisplaySize.equals("s")) {
      mFields = $.gSmallField as Array<Number>;
      mZenMode = $.gSmallFieldZen;
    } else if (mDisplaySize.equals("w")) {
      mFields = $.gWideField as Array<Number>;
      mZenMode = $.gWideFieldZen;
    } else {
      mFields = $.gLargeField as Array<Number>;
      mZenMode = $.gLargeFieldZen;
    }

    mGrid = [] as Array<Array<Array<Number> > >;

    var h_1fourth = h / 4;
    var h_center = h - 2 * h_1fourth;

    mYoffsetFix = 0;
    var w_side = (w * 2) / 5;
    if (mDisplaySize.equals("w")) {
      w_side = w / 3;
      mYoffsetFix = 1;
    }
    var w_center = w - 2 * w_side;
    var row = [
      [w_side, h_1fourth],
      [w_center, h_1fourth],
      [w_side, h_1fourth],
    ];

    mGrid.add(row as Array<Array<Number> >);

    var centerRow = [
      [w / 2, h_center],
      [w / 2, h_center],
    ];
    mGrid.add(centerRow as Array<Array<Number> >);

    mGrid.add(row as Array<Array<Number> >);
  }

  function compute(info as Activity.Info) as Void {
    mMetrics.compute(info);

    mPaused = false;
    if (info has :timerState) {
      mPaused = info.timerState == Activity.TIMER_STATE_PAUSED or info.timerState == Activity.TIMER_STATE_OFF;
    }

    if (mPaused) {
      mActivityStartCountdown = 5;
    } else if (mActivityStartCountdown >= 0) {
      mActivityStartCountdown--;
    }
    var power = mMetrics.getPower();
    var perc = percentageOf(power, gTargetFtp);
    mHiitt.compute(info, perc, power);

    if (power > 0.0 and mPowerFallbackCountdown < 5) {
      mPowerFallbackCountdown = $.gPowerCountdownToFallBack;
    } else if (mPowerFallbackCountdown > 0) {
      mPowerFallbackCountdown--;
    }
    var cadence = mMetrics.getCadence();
    if (cadence > 0.0 and mCadenceFallbackCountdown < 5) {
      mCadenceFallbackCountdown = $.gCadenceCountdownToFallBack;
    } else if (mCadenceFallbackCountdown > 0) {
      mCadenceFallbackCountdown--;
    }
  }

  function onUpdate(dc as Dc) as Void {
    if ($.gExitedMenu) {
      // fix for leaving menu, draw complete screen, large field
      dc.clearClip();
      $.gExitedMenu = false;
    }

    dc.setColor(getBackgroundColor(), getBackgroundColor());
    dc.clear();

    mFontColor = Graphics.COLOR_BLACK;
    mDecimalsColor = mDecimalsColorDay;
    mUnitsColor = mUnitsColorDay;
    mIconColor = mIconColorDay;
    if (getBackgroundColor() == Graphics.COLOR_BLACK) {
      mFontColor = Graphics.COLOR_WHITE;
      mDecimalsColor = mDecimalsColorNight;
      mUnitsColor = mUnitsColorNight;
      mIconColor = mIconColorNight;
    }
    dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);

    // top left, middle, right
    // centerleft, middle, right
    // bottom left, middle, right
    // !! Less nested function, less stack -> no stack overflow crash :-(
    // showGrid(dc);

    var y = 0;
    var f = 0;
    var rowCount = mGrid.size();
    for (var r = 0; r < rowCount; r++) {
      var row = mGrid[r]; // as Array<Array<Number> >;
      var cellCount = row.size();
      var x = 0;
      var h = 0;
      for (var c = 0; c < cellCount; c++) {
        //  [w,h]
        var cell = row[c]; // as Array<Number>;

        if (gShowGrid) {
          dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
          dc.drawRectangle(x, y, cell[0], cell[1]);
        }

        // drawField(dc, f, x, y, cell[0], cell[1]);
        var ft = FTUnknown;
        if (f < mFields.size()) {
          ft = mFields[f] as FieldType;
        }
        var fi = getFieldInfo(ft, f);
        
        // If field not available, get fallback field
        var fbProcessed = [] as Array<FieldType>;        
        while (!fi.available) {
          System.println("Check fallback for " + fi.type);
          var fb = getFallbackField(fi.type);
          if (fb == FTUnknown || fbProcessed.indexOf(fb) > -1) {
            fi.available = true;
          } else {
            fbProcessed.add(fb);
            var old = fi.type;
            fi = getFieldInfo(fb, f);
            System.println("Fallback from " + old + " to " + fi.type);
          }
        }

        drawFieldBackground(dc, fi, x, y, cell[0], cell[1]);
        drawFieldInfo(dc, fi, x, y, cell[0], cell[1]);

        x = x + cell[0];
        h = cell[1];
        f = f + 1;
      }
      y = y + h;
    }

    if ($.gDebug) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      var font = Graphics.FONT_SYSTEM_SMALL;
      var text = Lang.format("$1$x$2$ $3$", [dc.getWidth(), dc.getHeight(), mDisplaySize]);
      dc.drawText(
        dc.getWidth() / 2,
        dc.getHeight() / 2,
        font,
        text,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
  }

  function getFallbackField(fieldType as FieldType) as FieldType {
    switch (fieldType) {
      case FTPower:
        return $.gFBPower;
      case FTPowerPerWeight:
        return $.gFBPowerPerWeight;
      case FTPowerBalance:
        return $.gFBPowerBalance;
      case FTHeartRate:
        return $.gFBHeartRate;
      case FTHeartRateZone:
        return $.gFBHeartRateZone;
      case FTDistanceNext:
        return $.gFBDistanceNext;
      case FTDistanceDest:
        return $.gFBDistanceDest;
      case FTHiit:
        return $.gFBHiit;
      case FTAltitude:
        return $.gFBAltitude;
      case FTGrade:
        return $.gFBGrade;
      case FTCadence:
        return $.gFBCadence;
      case FTGearCombo:
        return $.gFBGearCombo;
      case FTGearIndex:
        return $.gFBGearIndex;
      default:
        return FTUnknown;
    }
  }
  function getFieldInfo(fieldType as FieldType, fieldIdx as Number) as FieldInfo {
    var available = true;
    var title = "";
    var value = "";
    var prefix = "";
    var text = "";
    var number = "";
    var decimals = "";
    var units = "";
    var units_side = "";
    var text_botright = "";
    var text_botleft = "";

    var text_middleleft = "";
    var text_middleright = "";
    var iconColor = -1;
    var iconValue = 0;

    switch (fieldType) {
      case FTDistance:
        title = "distance";
        var dist = mMetrics.getElapsedDistance();
        text = getDistanceInMeterOrKm(dist).format(getFormatForMeterAndKm(dist));
        units_side = getUnitsInMeterOrKm(dist);
        break;
      case FTDistanceNext:
        title = "next";
        var distNext = mMetrics.getDistanceToNextPoint();
        available = distNext > 0;
        text = getDistanceInMeterOrKm(distNext).format(getFormatForMeterAndKm(distNext));
        units_side = getUnitsInMeterOrKm(distNext);
        break;
      case FTDistanceDest:
        title = "dest";
        var distDest = mMetrics.getDistanceToDestination();
        available = distDest > 0;
        text = getDistanceInMeterOrKm(distDest).format(getFormatForMeterAndKm(distDest));
        units_side = getUnitsInMeterOrKm(distDest);
        break;
      case FTGrade:
        title = "grade";
        fieldType = FTGrade;
        var grade = mMetrics.getGrade();

        if (gGradeFallbackStart < gGradeFallbackEnd) {
          available = grade <= gGradeFallbackStart or grade >= gGradeFallbackEnd;
        }

        value = grade.format("%0.1f");
        if (mDisplaySize.equals("s")) {
          text = value;
          units_side = "%";
        } else {
          units = "%";
          number = stringLeft(value, ".", value);
          decimals = stringRight(value, ".", "");
        }
        var g = grade;
        if (grade < 0) {
          grade = grade * -1;
        }
        iconColor = getIconColor(grade, gTargetGrade);
        iconValue = g;
        break;
      case FTClock:
        title = "clock";
        fieldType = FTClock;
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        text = Lang.format("$1$:$2$", [today.hour, today.min.format("%02d")]);
        decimals = today.sec.format("%02d");
        units = Lang.format("$1$ $2$ $3$", [today.day_of_week, today.day, today.month]);
        break;

      case FTHeartRate:
        var heartRate = mMetrics.getHeartRate();
        available = heartRate > 0;
        title = "heartrate";
        fieldType = FTHeartRate;
        units = "bpm";

        if (gShowAverageWhenPaused && mPaused) {
          heartRate = mMetrics.getAverageHeartRate();
          iconValue = mMetrics.getHeartRateZone(true);
          units = "~bpm";
        } else {
          iconValue = mMetrics.getHeartRateZone(false);
        }
        number = heartRate.format("%0d");

        iconColor = getIconColor(heartRate, gTargetHeartRate);
        text_botleft = "zone " + iconValue.format("%0d");
        break;

      case FTPower:
        // @@ TODO special field by index
        // if (mMetrics.getFrontDerailleurSize() > 0) {
        //   text_middleright = mMetrics.getFrontDerailleurSize().format("%0d");
        // }

        var power = mMetrics.getPower();
        available = power > 0 and (mPowerFallbackCountdown > 0 or $.gPowerCountdownToFallBack == 0);

        if (mMetrics.getHasFailingDualpower()) {
          prefix = "2*";
        }
        title = "power (" + mMetrics.getPowerPerSec().format("%0d") + " sec)";
        fieldType = FTPower;
        units = "w";
        if (gShowAverageWhenPaused && mPaused) {
          number = mMetrics.getAveragePower().format("%0d");
          units = "~w";
        } else {
          number = mMetrics.getPower().format("%0d");
        }
        // @@ extra details in field .. option antizen mode
        // if (gShowPowerAverage) {
        //   text_botleft = "avg " + mMetrics.getAveragePower().format("%0d");
        // } else {
        //   text_botleft = mMetrics.getPowerPerWeight().format("%0.1f") + "/kg";
        // }
        iconColor = getIconColor(mMetrics.getPower(), gTargetFtp);
        break;

      case FTBearing:
        text = getCompassDirection(mMetrics.getBearing());
        fieldType = FTBearing;

        break;
      case FTSpeed:
        // if (mMetrics.getRearDerailleurSize() > 0) {
        //   text_middleleft = mMetrics.getRearDerailleurSize().format("%0d");
        // }
        title = "speed";
        fieldType = FTSpeed;
        units = "km/h";
        var speed;
        if (gShowAverageWhenPaused && mPaused) {
          speed = mpsToKmPerHour(mMetrics.getAverageSpeed());
          units = "~km/h";
        } else {
          speed = mpsToKmPerHour(mMetrics.getSpeed());
        }
        value = speed.format("%0.1f");
        number = stringLeft(value, ".", value);
        decimals = stringRight(value, ".", "");
        iconColor = getIconColor(speed, gTargetSpeed);
        // text_botleft = "avg " + mpsToKmPerHour(mMetrics.getAverageSpeed()).format("%0.1f");
        break;

      case FTAltitude:
        title = "altitude";
        fieldType = FTAltitude;
        units = "m";
        var altitude = mMetrics.getAltitude();

        if (gAltitudeFallbackStart < gAltitudeFallbackEnd) {
          available = altitude <= gAltitudeFallbackStart or altitude >= gAltitudeFallbackEnd;
        }

        if (mpsToKmPerHour(mMetrics.getSpeed()) < 15) {
          value = altitude.format("%0.2f");
        } else {
          value = altitude.format("%0d");
        }

        if (mDisplaySize.equals("w")) {
          number = value;
          units_side = "m";
        } else {
          number = stringLeft(value, ".", value);
          decimals = stringRight(value, ".", "");
        }

        if (altitude < 0) {
          altitude = altitude * -1;
        }
        iconColor = getIconColor(altitude, gTargetAltitude);

        var totalAsc = mMetrics.getTotalAscent();
        if (totalAsc > 0) {
          text_botleft = "A " + totalAsc.format("%0.0f");
        }
        var totalDesc = mMetrics.getTotalDescent();
        if (totalDesc > 0) {
          text_botright = "D " + totalDesc.format("%0.0f");
        }

        break;

      case FTCadence:
        title = "cadence";
        fieldType = FTCadence;
        units = "rpm";
        available = mMetrics.getCadence() > 0 and (mCadenceFallbackCountdown > 0 or $.gCadenceCountdownToFallBack == 0);

        var cadence;
        if (gShowAverageWhenPaused && mPaused) {
          cadence = mMetrics.getAverageCadence();
          units = "~rpm";
        } else {
          cadence = mMetrics.getCadence();
        }
        number = cadence.format("%0d");
        if (mDisplaySize.equals("w")) {
          units_side = "rpm";
        }
        iconColor = getIconColor(cadence, gTargetCadence);
        break;

      case FTHiit:
        // @@ TODO, keep bottom information / stats field
        // available  = mHiitt.isHiitInProgress
        available = false;
        if (mHiitt.isEnabled()) {
          available = true;
          title = "hiit";
          fieldType = FTHiit;

          var vo2max = mHiitt.getVo2Max();
          if (vo2max > 30) {
            text = vo2max.format("%0.1f");
          }

          var recovery = mHiitt.getRecoveryElapsedSeconds();
          if (recovery > 0) {
            text = secondsToCompactTimeString(recovery, "({m}:{s})");
            if (mHiitt.wasValidHiit()) {
              iconColor = Graphics.COLOR_BLUE;
            }
          } else {
            var counter = mHiitt.getCounter();
            if (counter > 0) {
              text = counter.format("%01d");
            } else {
              var hiitElapsed = mHiitt.getElapsedSeconds();
              if (hiitElapsed > 0) {
                text = secondsToCompactTimeString(hiitElapsed, "({m}:{s})");
                if (mHiitt.wasValidHiit()) {
                  iconColor = Graphics.COLOR_GREEN;
                }
                vo2max = mHiitt.getVo2Max();
                if (vo2max > 30) {
                  decimals = vo2max.format("%0.1f");
                }
              }
            }
          }
          var nrHiit = mHiitt.getNumberOfHits();
          if (nrHiit > 0) {
            text_botleft = "H " + nrHiit.format("%0.0d");
            text_botleft += " " + mHiitt.getHistStatusAsString();
          } else {
            text_botleft = mHiitt.getHistStatusAsString();
          }

          var scores = mHiitt.getHitScores();
          if (scores.size() > 0) {
            var sCounter = 0;

            for (var sIdx = scores.size() - 1; sIdx >= 0 and sCounter < 4; sIdx--) {
              var score = scores[sIdx] as Float;

              text_botright = text_botright + " " + score.format("%0.0f");
              sCounter++;
            }
          }
        }

        break;
      case FTTimer:
        title = "timer";
        var timerTime = millisecondsToShortTimeString(mMetrics.getTimerTime(), "{h}.{m}:{s}");
        prefix = stringLeft(timerTime, ".", "");
        if (prefix.equals("0")) {
          prefix = "";
        }
        text = stringRight(timerTime, ".", timerTime);
        break;
      case FTTimeElapsed:
        title = "elapsed";
        var elapsedTime = millisecondsToShortTimeString(mMetrics.getElapsedTime(), "{h}.{m}:{s}");
        prefix = stringLeft(elapsedTime, ".", "");
        if (prefix.equals("0")) {
          prefix = "";
        }
        text = stringRight(elapsedTime, ".", elapsedTime);
        break;
      case FTGearCombo:
        title = "gear combo";
        available = mMetrics.getFrontDerailleurSize() > 0;
        text = mMetrics.getFrontDerailleurSize().format("%0d") + ":" + mMetrics.getRearDerailleurSize().format("%0d");

        break;
      case FTPowerPerWeight:
        title = "power (" + mMetrics.getPowerPerSec().format("%0d") + " sec) / kg";
        var powerpw = mMetrics.getPowerPerWeight();
        available = powerpw > 0 and (mPowerFallbackCountdown > 0 or $.gPowerCountdownToFallBack == 0);
        units = "w/kg";

        if (mMetrics.getHasFailingDualpower()) {
          prefix = "2*";
        }

        if (gShowAverageWhenPaused && mPaused) {
          value = mMetrics.getAveragePowerPerWeight().format("%0.1f");
          units = "~w/kg";
        } else {
          value = powerpw.format("%0.1f");
        }
        number = $.stringLeft(value, ".", value);
        decimals = $.stringRight(value, ".", "");
        break;

      case FTPowerBalance:
        title = "power balance";
        available = mMetrics.getPower() > 0 and (mPowerFallbackCountdown > 0 or $.gPowerCountdownToFallBack == 0);

        var pLeft = mMetrics.getPowerBalanceLeft();
        if (gShowAverageWhenPaused && mPaused) {
          pLeft = mMetrics.getAveragePowerBalanceLeft();
        }
        if (pLeft > 0 and pLeft < 100) {
          var pRight = 100 - (pLeft as Number);
          text = Lang.format("$1$:$2$", [(pLeft as Number).format("%02d"), pRight.format("%02d")]);
        }
        break;
      case FTHeartRateZone:
        title = "heartrate zone";
        available = mMetrics.getHeartRate() > 0;
        text = mMetrics.getHeartRateZone(gShowAverageWhenPaused && mPaused).format("%d");
        break;
      case FTGearIndex:
        title = "gear index";
        available = mMetrics.getFrontDerailleurSize() > 0;
        text = mMetrics.getFrontDerailleurIndex().format("%0d") + ":" + mMetrics.getRearDerailleurIndex().format("%0d");
        break;
    }

    var fi = new FieldInfo();
    fi.available = available;
    fi.index = fieldIdx;
    fi.type = fieldType as FieldType;
    fi.title = title;
    fi.value = value;
    fi.prefix = prefix;
    fi.text = text;
    fi.number = number;
    fi.decimals = decimals;
    fi.text_middleleft = text_middleleft;
    fi.text_middleright = text_middleright;
    fi.iconColor = iconColor;
    fi.iconValue = iconValue;
    fi.units = units;
    fi.units_side = units_side;
    fi.text_botleft = text_botleft;
    fi.text_botright = text_botright;

    return fi;
  }

  function drawFieldBackground(
    dc as Dc,
    fieldInfo as FieldInfo,
    x as Number,
    y as Number,
    width as Number,
    height as Number
  ) as Void {
    var fi = fieldInfo;

    checkReverseColor(dc, x, y, width, height);

    if (fi.type == FTUnknown) {
      return;
    }
    if (fi.type == FTDistance) {
      drawDistanceIcon(dc, x, y, width, height, mIconColor);
      return;
    }
    if (fi.type == FTDistanceNext) {
      drawNextIcon(dc, x, y, width, height, mIconColor);
      return;
    }
    if (fi.type == FTDistanceDest) {
      drawDestinationIcon(dc, x, y, width, height, mIconColor);
      return;
    }
    if (fi.type == FTGrade) {
      drawGradeIcon(dc, x, y, width, height, fi.iconColor, fi.iconValue.toDouble());
      return;
    }
    if (fi.type == FTClock || fi.type == FTTimeElapsed || fi.type == FTTimer) {
      drawElapsedTimeIcon(dc, x, y, width, height, mIconColor, fi.iconValue.toNumber());
      return;
    }
    if (fi.type == FTHeartRate) {
      drawHeartIcon(dc, x, y, width, height, fi.iconColor, fi.iconValue.toNumber());
      return;
    }
    if (fi.type == FTPower) {
      drawPowerIcon(dc, x, y, width, height, fi.iconColor);

      if ($.gShowPowerBattery) {
        var batteryLevel = mMetrics.getPowerBatteryLevel();
        var operatingTimeInSeconds = mMetrics.getPowerOperatingTimeInSeconds();

        if (operatingTimeInSeconds > 0 and gPowerBattSetRemainingHour > 0) {
          var spentSeconds = $.gPowerBattMaxSeconds - gPowerBattSetRemainingHour * 60 * 60;
          if (spentSeconds > 0) {
            gPowerBattOperTimeCharched = operatingTimeInSeconds - spentSeconds;
            Storage.setValue("metric_pbattopertimecharched", gPowerBattOperTimeCharched);
            gPowerBattFullyCharched = true;
            Storage.setValue("metric_pbattfullycharched", gPowerBattFullyCharched);
          }
          gPowerBattSetRemainingHour = 0;
          Storage.setValue("metric_pbattsetremaininghour", gPowerBattSetRemainingHour);
        }

        // If fully charched, save operatingtime of powermeter
        if (batteryLevel == 5 and !gPowerBattFullyCharched) {
          $.gPowerBattOperTimeCharched = operatingTimeInSeconds;
          Storage.setValue("metric_pbattopertimecharched", gPowerBattOperTimeCharched);
          $.gPowerBattFullyCharched = true;
          Storage.setValue("metric_pbattfullycharched", gPowerBattFullyCharched);
        } else if (batteryLevel == 4 and gPowerBattFullyCharched) {
          $.gPowerBattFullyCharched = false;
          Storage.setValue("metric_pbattfullycharched", gPowerBattFullyCharched);
        }

        var operatingTimeAfterCharched = operatingTimeInSeconds - gPowerBattOperTimeCharched;
        var powerTimeString = "";
        if (
          !mDisplaySize.equals("s") and
          $.gShowPowerBattTime and
          //!mSmallField and
          operatingTimeInSeconds > -1 and
          operatingTimeAfterCharched > 0 and
          (batteryLevel <= 3 or mPaused)
        ) {
          if ($.gPowerBattMaxSeconds == 0) {
            // o perating time
            powerTimeString = "o " + secondsToHourMinutes(operatingTimeAfterCharched);
          } else {
            var remainingSeconds = $.gPowerBattMaxSeconds - operatingTimeAfterCharched;
            // r emaining time
            if (remainingSeconds >= 0) {
              powerTimeString = "rpp " + secondsToHourMinutes(operatingTimeAfterCharched);
            }
          }
        }
        drawPowerBatteryLevel(dc, x, y, width, height, batteryLevel, powerTimeString);
      }
      return;
    }
    if (fi.type == FTBearing) {
      // @@ drawBearingIcon(dc, x, y, width, height, mIconColor);
      return;
    }
    if (fi.type == FTSpeed) {
      drawSpeedIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTAltitude) {
      drawAltitudeIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTPressureAtSea) {
      // @@ drawPressureAtSeaIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTPressure) {
      // @@ drawPressureIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTCadence) {
      drawCadenceIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTHiit && fi.iconColor != -1) {
      drawHiitIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTGearCombo) {
      // @@ drawGearComboIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTPowerPerWeight) {
      // @@ drawPowerPerWeightIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTPowerBalance) {
      // @@ drawPowerBalanceIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
  }

  function drawFieldInfo(
    dc as Dc,
    fieldInfo as FieldInfo,
    x as Number,
    y as Number,
    width as Number,
    height as Number
  ) as Void {
    var title = fieldInfo.title;
    var value = fieldInfo.value;
    var prefix = fieldInfo.prefix;
    var text = fieldInfo.text;
    var number = fieldInfo.number;
    var decimals = fieldInfo.decimals;

    var units = fieldInfo.units;
    var units_side = fieldInfo.units_side;

    var text_botleft = fieldInfo.text_botleft;
    var text_botright = fieldInfo.text_botright;
    var text_middleleft = fieldInfo.text_middleleft;
    var text_middleright = fieldInfo.text_middleright;

    var hideDetails = false;
    if (fieldInfo.type != FTHiit) {
      if (mZenMode == ZMOn) {
        hideDetails = true;
      } else if (mZenMode == ZMOff) {
        hideDetails = false;
      } else if (mZenMode == ZMWhenMoving) {
        hideDetails = !mPaused;
      }
      if (hideDetails) {
        text_botleft = "";
        text_botright = "";
        units = "";
        units_side = "";
      }
    }

    // small fields, no decimals and units
    // System.println([height, width]);
    var font_text_bot = Graphics.FONT_SMALL;
    var fontUnits = Graphics.FONT_SYSTEM_XTINY;
    if (height > 60 and height < 100) {
      text_middleleft = "";
      text_middleright = "";
    }
    if (height < 60) {
      font_text_bot = Graphics.FONT_XTINY;
    }
    if (height < 30) {
      decimals = "";
      units = "";
      text_botright = "";
      text_botleft = "";
    }
    if (width <= 70) {
      text_botright = "";
      text_botleft = "";
      text_middleleft = "";
      text_middleright = "";
    }
    if (decimals.equals("0")) {
      decimals = "";
    }
    var dims_prefix = [0, 0] as Array<Number>;
    var dims_number_or_text = [0, 0] as Array<Number>;
    var dims_decimals = [0, 0] as Array<Number>;
    var dims_units = [0, 0] as Array<Number>;

    var fontPrefix = Graphics.FONT_SYSTEM_XTINY;
    if (prefix.length() > 0) {
      dims_prefix = dc.getTextDimensions(prefix, fontPrefix);
    }

    if (units.length() > 0) {
      dims_units = dc.getTextDimensions(units, fontUnits);
    } else if (units_side.length() > 0) {
      dims_units = dc.getTextDimensions(units_side, fontUnits);
    }

    // @@ when alpha working + show in paused and until 1 minute
    if (mPaused or (mActivityStartCountdown > 0 and title.length() > 0)) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawText(x + 1, y, Graphics.FONT_SYSTEM_XTINY, title, Graphics.TEXT_JUSTIFY_LEFT);
    }

    if (mReverseColor) {
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    } else {
      dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
    }

    if (text.length() > 0 or number.length() > 0) {
      var font = Graphics.FONT_NUMBER_HOT;
      var number_or_text = "";
      if (text.length() > 0) {
        number_or_text = text;
        font = getMatchingFont(dc, mFonts, width, height, text) as FontType;
        dims_number_or_text = dc.getTextDimensions(number_or_text, font);
      } else if (number.length() > 0) {
        number_or_text = number;
        font = getMatchingFont(dc, mFontsNumbers, width, height, number) as FontType;
        dims_number_or_text = dc.getTextDimensions(number, font);
      }

      var fontDecimals = Graphics.FONT_SYSTEM_MEDIUM;
      if (decimals.length() > 0) {
        if (height < 100) {
          fontDecimals = Graphics.FONT_SYSTEM_SMALL;
        } else if (height < 45) {
          fontDecimals = Graphics.FONT_SYSTEM_TINY;
        }
        if (font == fontDecimals) {
          fontDecimals = Graphics.FONT_XTINY;
        }
        dims_decimals = dc.getTextDimensions(decimals, fontDecimals);
      }

      var xSplit = (x + (width - dims_number_or_text[0] - dims_decimals[0]) / 2 + dims_number_or_text[0]).toNumber();
      var yBase = y + (height - dims_number_or_text[1]) / 2;
      dc.drawText(xSplit, yBase + mYoffsetFix, font, number_or_text, Graphics.TEXT_JUSTIFY_RIGHT);

      if (decimals.length() > 0) {
        var yDec =
          yBase +
          dims_number_or_text[1] -
          dims_decimals[1] -
          Graphics.getFontDescent(font) +
          Graphics.getFontDescent(fontDecimals);

        if (mReverseColor) {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
          dc.setColor(mDecimalsColor, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(xSplit, yDec, fontDecimals, decimals, Graphics.TEXT_JUSTIFY_LEFT);
      }

      if (units.length() > 0) {
        var yUnits =
          yBase +
          dims_number_or_text[1] -
          dims_units[1] -
          Graphics.getFontDescent(font) +
          Graphics.getFontDescent(fontUnits);

        if (mReverseColor) {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
          dc.setColor(mUnitsColor, Graphics.COLOR_TRANSPARENT);
        }
        var xUnits = xSplit + dims_decimals[0] + 1;
        if (xUnits + dims_units[0] > width) {
          // Units on center bottom when small field (@@ +1 fix for edge 1040
          // display not same as on simulator)
          xUnits = x + width / 2 - dims_units[0] / 2;
          yUnits = yBase + dims_number_or_text[1] - Graphics.getFontDescent(font) + 1; // not needed on device - Graphics.getFontDescent(fontUnits)
        }
        dc.drawText(xUnits, yUnits, fontUnits, units, Graphics.TEXT_JUSTIFY_LEFT);
      } else if (units_side.length() > 0) {
        var yUnits =
          yBase +
          dims_number_or_text[1] -
          dims_units[1] -
          Graphics.getFontDescent(font) +
          Graphics.getFontDescent(fontUnits);

        if (mReverseColor) {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
          dc.setColor(mUnitsColor, Graphics.COLOR_TRANSPARENT);
        }
        var xUnits = x + width - 1;
        dc.drawText(xUnits, yUnits, fontUnits, units_side, Graphics.TEXT_JUSTIFY_RIGHT);
      }

      if (text_botright.length() > 0) {
        dc.setColor(mDecimalsColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
          x + width - 1,
          y + height - dc.getFontHeight(font_text_bot),
          font_text_bot,
          text_botright,
          Graphics.TEXT_JUSTIFY_RIGHT
        );
      }
      if (text_botleft.length() > 0) {
        dc.setColor(mDecimalsColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
          x + 1,
          y + height - dc.getFontHeight(font_text_bot),
          font_text_bot,
          text_botleft,
          Graphics.TEXT_JUSTIFY_LEFT
        );
      }

      if (prefix.length() > 0) {
        var xPrefix = xSplit - dims_number_or_text[0] - dims_prefix[0];
        var yPrefix = y + height / 2 - dims_number_or_text[1] / 2; // - dims_prefix[1] / 2;
        dc.setColor(mUnitsColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPrefix, yPrefix, fontPrefix, prefix, Graphics.TEXT_JUSTIFY_LEFT);
      }
    }

    if (text_middleleft.length() > 0) {
      dc.drawText(x + 1, y + height / 4, Graphics.FONT_SYSTEM_TINY, text_middleleft, Graphics.TEXT_JUSTIFY_LEFT);
    }
    if (text_middleright.length() > 0) {
      dc.drawText(
        x + width - 1,
        y + height / 4,
        Graphics.FONT_SYSTEM_TINY,
        text_middleright,
        Graphics.TEXT_JUSTIFY_RIGHT
      );
    }
  }

  hidden function getIconColor(value as Numeric, maxValue as Numeric) as Graphics.ColorType {
    mReverseColor = false;
    if (gShowColors and gCreateColors) {
      var perc = percentageOf(value, maxValue);
      var darker = 0;
      if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        darker = 30;
      } else {
        mReverseColor = perc >= 165;
      }
      return percentageToColor(perc, 255, $.PERC_COLORS_SCHEME, darker);
    } else {
      return mIconColor;
    }
  }

  hidden function checkReverseColor(dc as Dc, x as Number, y as Number, width as Number, height as Number) as Void {
    if (mReverseColor) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillRectangle(x, y, width, height);
    }
  }

  hidden function drawHeartIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    hrZone as Number
  ) as Void {
    var r = (height / 3.85).toNumber();
    var x0 = (x + width / 2).toNumber();
    var y1 = (y + 1.5 * r).toNumber();
    var x1 = (x0 - 0.9 * r).toNumber();
    var x2 = (x1 + 1.8 * r).toNumber();

    var xc1 = pointOnCircle_x(x1, y1, r, 135);
    var yc1 = pointOnCircle_y(x1, y1, r, 135);
    var xc2 = pointOnCircle_x(x2, y1, r, 45);
    var yc2 = pointOnCircle_y(x2, y1, r, 45);
    var y3 = (y + height - 0.5 * r).toNumber();

    var hrzFont = Graphics.FONT_SYSTEM_NUMBER_MILD;
    var fh = dc.getFontHeight(hrzFont);
    if (fh > height) {
      hrzFont = Graphics.FONT_SMALL;
    }

    // hr zone
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      x + 2,
      y + height / 2 - 1,
      hrzFont,
      hrZone.format("%0d"),
      Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
    );
    setColorFillStroke(dc, color);

    dc.fillCircle(x1, y1, r);
    dc.fillCircle(x2, y1, r);
    dc.fillPolygon(
      [
        [xc1, yc1],
        [x0, y3],
        [xc2, yc2],
        [x0, y1],
      ] as Array<Point2D>
    );
  }
  hidden function drawGradeIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    grade as Double
  ) as Void {
    var m = height / 8;
    x = x + m;
    y = y + m;
    width = width - 2 * m;
    height = height - 2 * m;

    setColorFillStroke(dc, color);
    var f = grade / 10.0;
    if (f < 0) {
      f = f * -1.0;
    }

    var h = height / 2;
    var w = width / 2;
    var xc = x + w;
    var yc = y + h;

    var xp = w;
    var yp = 0;
    if (f != 0.0) {
      yp = f * w;
      if (yp > h) {
        xp = h / f;
        yp = h;
      }
    }
    if (grade > 0) {
      if (yp == h) {
        dc.fillPolygon(
          [
            [xc + xp, yc - yp],
            [x + width, y],
            [x + width, y + height],
            [xc - xp, y + height],
          ] as Array<Point2D>
        );
      } else {
        dc.fillPolygon(
          [
            [xc + xp, yc - yp],
            [x + width, y + height],
            [x, y + height],
            [x, yc + yp],
          ] as Array<Point2D>
        );
      }
      // dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      // dc.drawLine(xc, yc, xc + xp, yc - yp);
    } else {
      if (yp == h) {
        dc.fillPolygon(
          [
            [xc + xp, yc + yp],
            [x, y + height],
            [x, y],
            [xc - xp, y],
          ] as Array<Point2D>
        );
      } else {
        dc.fillPolygon(
          [
            [xc + xp, yc + yp],
            [x + width, y + height],
            [x, y + height],
            [x, yc - yp],
          ] as Array<Point2D>
        );
      }
      // dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
      // dc.drawLine(xc, yc, xc + xp, yc + yp);
    }
  }

  hidden function drawSpeedIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var my = height / 5;
    var mx = width / 8;

    var x1 = x + mx;
    var y1 = y + my;
    var x2 = x + mx;
    var y2 = y + height - my;
    var x3 = x + width - mx;
    var y3 = y + height / 2;

    setColorFillStroke(dc, color);
    dc.fillPolygon(
      [
        [x1, y1],
        [x2, y2],
        [x3, y3],
      ] as Array<Point2D>
    );
  }
  hidden function drawDistanceIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var my = height / 8;
    var mx = width / 5;

    var x1 = x + mx;
    var y1 = y + my;
    var y2 = y + height - my;

    var x2 = x + 2 * mx;

    var x3 = x + 3 * mx;
    var yc = y + height / 2;
    var x4 = x + 4 * mx;

    setColorFillStroke(dc, color);
    dc.fillPolygon(
      [
        [x2, y1],
        [x2, y2],
        [x1, yc],
      ] as Array<Point2D>
    );

    dc.fillRectangle(x2, yc - (my / 2), x3 - x2, my);
    
    dc.fillPolygon(
      [
        [x3, y1],
        [x3, y2],
        [x4, yc],
      ] as Array<Point2D>
    );
  }
  hidden function drawNextIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var my = height / 8;
    var mx = width / 4;

    var x1 = x + mx;
    var y1 = y + my;
    var y2 = y + height - my;

    var x2 = x + 2 * mx;
    var yc = y + height / 2;
    var x3 = x + 3 * mx;

    setColorFillStroke(dc, color);
    dc.fillPolygon(
      [
        [x1, y1],
        [x1, y2],
        [x2, yc],
      ] as Array<Point2D>
    );
    dc.fillPolygon(
      [
        [x2, y1],
        [x2, y2],
        [x3, yc],
      ] as Array<Point2D>
    );
  }
  hidden function drawDestinationIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var my = height / 8;
    var mx = width / 4;

    var x1 = x + mx;
    var y1 = y + my;
    var y2 = y + height - my;

    var x2 = x + 2 * mx;
    var yc = y + height / 2;
    var x3 = x + 3 * mx;

    setColorFillStroke(dc, color);
    dc.fillPolygon(
      [
        [x1, y1],
        [x1, y2],
        [x2, yc],
      ] as Array<Point2D>
    );
    dc.fillPolygon(
      [
        [x2, y1],
        [x2, y2],
        [x3, yc],
      ] as Array<Point2D>
    );

    dc.fillRectangle(x3, y1, mx / 2, y2 - y1);
  }

  hidden function drawPowerIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var my = (height / 5).toNumber();
    var mx = (width / 6).toNumber();

    var halfWidth = (width / 2).toNumber();
    var halfHeight = (height / 2).toNumber();
    var mx13 = (mx * 1.3).toNumber();

    var x1 = x + halfWidth + mx;
    var y1 = y + my;

    var x2 = x + halfWidth - mx13;
    var y2 = y + halfHeight + 2;

    var x3 = x2 + mx;
    var y3 = y2;

    var x4 = x + halfWidth - mx;
    var y4 = y + height - my;

    var x5 = x + halfWidth + mx13;
    var y5 = y + halfHeight - 2;

    var x6 = x + halfWidth;
    var y6 = y5;

    setColorFillStroke(dc, color);
    dc.fillPolygon(
      [
        [x1, y1],
        [x2, y2],
        [x3, y3],
        [x4, y4],
        [x5, y5],
        [x6, y6],
      ] as Array<Point2D>
    );
  }

  hidden function drawPowerBatteryLevel(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    batteryLevel as Number,
    remainingTimeString as String
  ) as Void {
    if (batteryLevel < 0) {
      return;
    }

    var m = 2;
    var w = 17;
    var h = 7;
    var x1 = x + width - w - m;
    var y1 = y + 1 + m;

    if (batteryLevel >= 4) {
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    } else if (batteryLevel >= 3) {
      dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
    } else {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    }
    dc.drawRoundedRectangle(x1, y1, w, h, 2);
    dc.fillRectangle(x1 - 1, y1 + h / 2 - 2, 2, 4);
    for (var i = 0; i < batteryLevel; i++) {
      dc.fillRectangle(x1 + w - 1 - (i + 1) * 3, y1 + 1, 2, 5);
    }

    if (remainingTimeString.length() > 0) {
      dc.drawText(x1 - 2, y, Graphics.FONT_TINY, remainingTimeString, Graphics.TEXT_JUSTIFY_RIGHT);
    }
  }
  hidden function drawHiitIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(x, y, width, height);
  }

  hidden function drawCadenceIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var r = height / 3;
    if (width < height) {
      r = width / 3;
    }
    var x1 = x + width / 2;
    var y1 = y + height / 2;

    dc.setPenWidth(5);
    setColorFillStroke(dc, color);
    dc.drawCircle(x1, y1, r);
    dc.setPenWidth(1);
  }
  hidden function drawElapsedTimeIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    milliSeconds as Number
  ) as Void {
    var r = height / 3;
    if (width < height) {
      r = width / 3;
    }
    var x1 = x + width / 2;
    var y1 = y + height / 2;

    dc.setPenWidth(5);
    setColorFillStroke(dc, color);
    dc.drawCircle(x1, y1, r);

    dc.drawLine(x1, y1 - r, x1, y1 - r - 1);

    var hours = (milliSeconds / (1000.0 * 60 * 60)).toNumber() % 24;
    var minutes = (milliSeconds / (1000.0 * 60.0)).toNumber() % 60;

    var hDeg = (hours * 30 - 90) % 360;
    var mDeg = (minutes * 6 - 90) % 360;
    var xc1 = pointOnCircle_x(x1, y1, r, hDeg);
    var yc1 = pointOnCircle_y(x1, y1, r, hDeg);
    var xc2 = pointOnCircle_x(x1, y1, r - 2, mDeg);
    var yc2 = pointOnCircle_y(x1, y1, r - 2, mDeg);

    dc.drawLine(x1, y1, xc1, yc1);
    dc.setPenWidth(2);
    dc.drawLine(x1, y1, xc2, yc2);
    dc.setPenWidth(1);
  }

  hidden function drawAltitudeIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var m = (height / 5).toNumber();
    var d = (width / 6).toNumber();
    var x1 = x + d;
    var y1 = y + height - m;
    var x2 = (x1 + 1.5 * d).toNumber();
    var y2 = y + m;
    var x3 = (x2 + 0.5 * d).toNumber();
    var y3 = (y + 3 * m).toNumber();
    var x4 = x3 + d;
    var y4 = (y + 2 * m).toNumber();
    var x5 = x4 + d;
    var y5 = y1;

    setColorFillStroke(dc, color);
    dc.fillPolygon(
      [
        [x1, y1],
        [x2, y2],
        [x3, y3],
        [x4, y4],
        [x5, y5],
      ] as Array<Point2D>
    );
  }

  hidden function showDebugValues(dc as Dc) as Void {
    var font = Graphics.FONT_SMALL;
    var x = 1;
    var y = 1;
    var l = dc.getFontHeight(font);

    y = y + l;
    dc.drawText(x, y, font, Lang.format("Alt: $1$", [mMetrics.getAltitude()]), Graphics.TEXT_JUSTIFY_LEFT);
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format("Grade: $1$", [mMetrics.getGrade().format("%0.1f")]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    y = y + l;
    var grades = "";
    for (var i = 0; i < mMetrics.getGradeArray().size(); i++) {
      grades = grades + mMetrics.getGradeArray()[i].format("%0.2f") + " ";
    }
    dc.drawText(x, y, Graphics.FONT_SMALL, Lang.format("Grade: $1$", [grades]), Graphics.TEXT_JUSTIFY_LEFT);
    // y = y + l;
    // dc.drawText(
    //   x,
    //   y,
    //   font,
    //   Lang.format("Bearing: $1$", [getCompassDirection(mMetrics.getBearing())]),
    //   Graphics.TEXT_JUSTIFY_LEFT
    // );
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format("Power: $1$", [mMetrics.getPower().format("%0.0d")]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Battery level: $1$", [mMetrics.getPowerBatteryLevel().format("%0d")]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Battery voltage: $1$", [mMetrics.getPowerBatteryVoltage().format("%0.0f")]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    var operatingTimeInSeconds = mMetrics.getPowerOperatingTimeInSeconds();
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Oper seconds: $1$", [operatingTimeInSeconds.format("%0d")]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Set remaining HH: $1$", [gPowerBattSetRemainingHour.format("%0d")]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    var batteryLevel = mMetrics.getPowerBatteryLevel();
    if (operatingTimeInSeconds > 0 and gPowerBattSetRemainingHour > 0) {
      var spentSeconds = $.gPowerBattMaxSeconds - gPowerBattSetRemainingHour * 60 * 60;
      if (spentSeconds > 0) {
        gPowerBattOperTimeCharched = operatingTimeInSeconds - spentSeconds;
        Storage.setValue("metric_pbattopertimecharched", gPowerBattOperTimeCharched);
        gPowerBattFullyCharched = true;
        Storage.setValue("metric_pbattfullycharched", gPowerBattFullyCharched);
      }
      gPowerBattSetRemainingHour = 0;
      Storage.setValue("metric_pbattsetremaininghour", gPowerBattSetRemainingHour);
    }

    // If fully charched, save operatingtime of powermeter
    if (batteryLevel == 5 and !gPowerBattFullyCharched) {
      gPowerBattOperTimeCharched = operatingTimeInSeconds;
      Storage.setValue("metric_pbattopertimecharched", gPowerBattOperTimeCharched);
      gPowerBattFullyCharched = true;
      Storage.setValue("metric_pbattfullycharched", gPowerBattFullyCharched);
    } else if (batteryLevel == 4 and gPowerBattFullyCharched) {
      gPowerBattFullyCharched = false;
      Storage.setValue("metric_pbattfullycharched", gPowerBattFullyCharched);
    }

    var operatingTimeAfterCharched = operatingTimeInSeconds - gPowerBattOperTimeCharched;

    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. charged[$1$] Seconds after: $2$", [gPowerBattFullyCharched, operatingTimeAfterCharched]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Max (HH:MM): $1$", [secondsToHourMinutes($.gPowerBattMaxSeconds)]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Oper after charged (HH:MM): $1$", [secondsToHourMinutes(operatingTimeAfterCharched)]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    y = y + l;
    var remainingSeconds = $.gPowerBattMaxSeconds - operatingTimeAfterCharched;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Remain afer charged (HH:MM): $1$", [secondsToHourMinutes(remainingSeconds)]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    var HiitElapsed = mHiitt.getElapsedSeconds();
    var vo2max = mHiitt.getVo2Max();
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format("Hiit: #$1$ $2$ $3$", [
        mHiitt.getNumberOfHits().format("%0.0d"),
        HiitElapsed.format("%0.0d"),
        vo2max.format("%0.1f"),
      ]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawArrowUp(dc as Dc, x as Number, y as Number, width as Number, height as Number) as Void {
    var xm = x + width / 2;
    var yd = height / 3;
    var ym = y + yd;

    dc.fillPolygon(
      [
        [xm, y],
        [x, ym],
        [x + width, ym],
      ] as Array<Point2D>
    );
    dc.fillRectangle(xm - 1, ym, 3, height - yd);
  }

  function drawArrowDown(dc as Dc, x as Number, y as Number, width as Number, height as Number) as Void {
    var xm = x + width / 2;
    var yd = height / 3;
    var ym = y + height - yd;

    dc.fillRectangle(xm - 1, y, 3, height - yd);
    dc.fillPolygon(
      [
        [x, ym],
        [x + width, ym],
        [xm, y + height],
      ] as Array<Point2D>
    );
  }
}
