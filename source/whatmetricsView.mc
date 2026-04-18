import Toybox.Activity;
import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.Time;
import Toybox.Time.Gregorian;

class whatmetricsView extends WatchUi.DataField {
  const COLOR_LT_GRAY = 0xeeeeee;
  const COLOR_LT_BLUE = 0xade6e6;

  hidden var mLargeField as Boolean = false;
  hidden var mSmallField as Boolean = false;
  hidden var mWideField as Boolean = false;
  // hidden var mOneField as Boolean = false;

  hidden var mFieldSize as String;
  hidden var mYoffsetFix as Number = 0;

  hidden var mDebug as Boolean = true;
  hidden var mPaused as Boolean = true;
  // -1: ignore,
  hidden var mSecondsResumed as Number = -1;

  hidden var mActivityStartCountdown as Number = 0;
  hidden var mZenCountdown as Number = 0;
  hidden var mPowerFallbackCountdown as Number = 0;
  hidden var mCadenceFallbackCountdown as Number = 0;

  // [[w,h],[w,h],[w,h]]
  hidden var mGrid as Array<Array<Array<Number> > > =
    [] as Array<Array<Array<Number> > >;
  hidden var mFontColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mReverseColor as Boolean = false;
  hidden var mDecimalsColor as Graphics.ColorType = Graphics.COLOR_DK_GRAY;
  hidden var mDecimalsColorDay as Graphics.ColorType = Graphics.COLOR_DK_GRAY;
  hidden var mDecimalsColorNight as Graphics.ColorType = Graphics.COLOR_WHITE;
  hidden var mUnitsColor as Graphics.ColorType = Graphics.COLOR_DK_GRAY;
  hidden var mUnitsColorDay as Graphics.ColorType = Graphics.COLOR_DK_GRAY;
  hidden var mUnitsColorNight as Graphics.ColorType = Graphics.COLOR_WHITE;
  hidden var mIconColor as Graphics.ColorType = Graphics.COLOR_LT_GRAY;
  hidden var mIconColorDay as Graphics.ColorType = Graphics.COLOR_LT_GRAY;
  hidden var mIconColorNight as Graphics.ColorType = Graphics.COLOR_WHITE;

  hidden var mBarColorDay as Graphics.ColorType = Graphics.COLOR_DK_GRAY;
  hidden var mBarColorNight as Graphics.ColorType = Graphics.COLOR_WHITE;

  hidden var mFontsNumbers as Array = [
    Graphics.FONT_XTINY,
    Graphics.FONT_TINY,
    Graphics.FONT_SYSTEM_SMALL,
    Graphics.FONT_SYSTEM_MEDIUM,
    Graphics.FONT_SYSTEM_LARGE,
    Graphics.FONT_NUMBER_MILD,
    Graphics.FONT_NUMBER_MEDIUM,
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
  hidden var mDrawBackgroundHiittIcon as Boolean = false;
  // hidden var hiitBgColor as Graphics.ColorType = -1;
  // hidden var hiitBgImproving as Number = 0;
  hidden var mMetrics as WhatMetrics;
  hidden var mFields as Array<Number> = [] as Array<Number>;
  hidden var mFieldLayout as FieldLayout = FL8Fields;
  hidden var mZenMode as ZenMode = ZMOff;
  hidden var mZenHideDetails as Boolean = false;
  hidden var mBarPosition as BarPosition = BPOff;
  // hidden var mDisplaySize as String = "s";

  hidden var mDemoFields_FieldIndex as Number = $.FieldTypeCount;
  hidden var mDemoFt as FieldType = FTUnknown;
  hidden var mDemoFields_Counter as Number = -1;
  hidden var mBackgroundColor as Graphics.ColorType = 0xffffff;
  hidden var mBackgroundIsWhite as Boolean = false;
  hidden var mGraphicFieldHeight as Number = 0;
  hidden var mGraphicLineHeight as Number = 5;

  hidden var mCurrentLocation as CurrentLocation;
  hidden var mSunrise as Moment?;
  hidden var mSunset as Moment?;
  hidden var mSunriseTomorrow as Moment?;

  hidden var mDayLiteTime as Boolean;
  // hidden var mSunsetTomorrow as Moment?;
  hidden var mTestTick as Number = 0;

  // hidden var mGrade as Double = 0.0d;
  function initialize() {
    DataField.initialize();
    mFieldSize = "?x?";

    mHiitt = $.getHiitt() as WhatHiitt;
    mMetrics = $.getWhatMetrics() as WhatMetrics;

    $.checkFeatures();
    if ($.gCreateColors) {
      mDecimalsColorDay = Graphics.createColor(180, 50, 50, 50);
      mDecimalsColorNight = Graphics.createColor(180, 150, 150, 150);

      mUnitsColorDay = Graphics.createColor(180, 100, 100, 100);
      mUnitsColorNight = Graphics.createColor(180, 220, 220, 220);

      mIconColorDay = Graphics.createColor(255, 220, 220, 220);
      mIconColorNight = Graphics.createColor(255, 100, 100, 100);
    } else {
      mDecimalsColorDay = 0x323232; // 50,50,50
      mDecimalsColorNight = 0x969696; // 150,150,150
      mUnitsColorDay = 0x646464; // 100,100,100
      mUnitsColorNight = 0xdcdcdc; // 220,220,220
      mIconColorDay = 0xdcdcdc; // 220,220,220
      mIconColorNight = 0x646464; // 100,100,100
    }

    mCurrentLocation = new CurrentLocation();
    mCurrentLocation.setOnSunEventChanged(self, :onSunEventChanged);
    mCurrentLocation.setMinDegreesDifferenceSunevent(
      $.gSunEventDegreesDifference
    );
  }

  function onSunEventChanged(sunrise as Moment?, sunset as Moment?) {
    mSunrise = sunrise;
    mSunset = sunset;
    mSunriseTomorrow = mCurrentLocation.getSunriseTomorrow();

    System.println([
      "onSunEventChanged:",
      " sunrise:",
      $.getLongTimeString(sunrise),
      " sunset:",
      $.getLongTimeString(sunset),
    ]);
  }

  function isAtDaylightTime(time as Moment, defValue as Boolean) as Boolean {
    if (mSunrise == null || mSunset == null) {
      return defValue;
    }

    var dayLightTime =
      (mSunrise as Moment).value() <= time.value() &&
      time.value() <= (mSunset as Moment).value();

    System.println([
      "isAtDaylightTime:",
      dayLightTime.toString(),
      "sunrise:",
      $.getLongTimeString(mSunrise),
      "sunset:",
      $.getLongTimeString(mSunset),
      "when:",
      $.getLongTimeString(time),
    ]);

    return dayLightTime;
  }

  function onLayout(dc as Dc) as Void {
    // fix for leaving menu, draw complete screen, large field
    dc.clearClip();

    var h = dc.getHeight();
    var w = dc.getWidth();
    mFieldSize = Lang.format("$1$x$2$", [w, h]);

    mGraphicLineHeight = $.gGraphic_fields_line_width;

    var ef = $.getEdgeField(dc);
    mLargeField = ef == EfLarge || ef == EfOne;
    mSmallField = ef == EfSmall;
    mWideField = ef == EfWide;
    // mOneField = ef == EfOne;

    // mDisplaySize = $.getDisplaySize(w, h);
    if (mSmallField) {
      mFields = $.gSmallField as Array<Number>;
      mZenMode = $.gSmallFieldZen;
      mBarPosition = $.gSmallFieldBp;
      // @@QND
      if (mGraphicLineHeight > 2) {
        mGraphicLineHeight = 2;
      }
    } else if (mWideField) {
      mFields = $.gWideField as Array<Number>;
      mZenMode = $.gWideFieldZen;
      mBarPosition = $.gWideFieldBp;
      if (mGraphicLineHeight > 4) {
        mGraphicLineHeight = 4;
      }
    } else {
      mFields = $.gLargeField as Array<Number>;
      mZenMode = $.gLargeFieldZen;
      mBarPosition = $.gLargeFieldBp;
    }
    mFieldLayout = mFields[0] as FieldLayout;

    mGraphicFieldHeight = 0;
    if ($.gShow_graphic_fields && mBarPosition != BPOff) {
      // reserve space for extra graphical fields on top / bottom
      var divider = 0;
      for (var e = 0; e < $.gGraphic_fields.size(); e++) {
        var eft = $.gGraphic_fields[e] as FieldType;
        if (eft != FTUnknown && targetDataAvailable(eft)) {
          if (divider > 1) {
            // Add divider
            mGraphicFieldHeight = mGraphicFieldHeight + 1;
          }
          divider++;

          mGraphicFieldHeight = mGraphicFieldHeight + mGraphicLineHeight;
        }
      }
      h = h - mGraphicFieldHeight;
    }

    mGrid = [] as Array<Array<Array<Number> > >;

    var h_1fourth = h / 4;
    var h_center = h - 2 * h_1fourth;
    var h_halve = h / 2;

    mYoffsetFix = 0;
    var w_side = (w * 2) / 5;
    if (mWideField) {
      w_side = w / 3;
      mYoffsetFix = 1;
    }
    var w_center = w - 2 * w_side;

    var row;

    if (mFieldLayout == FL8Fields) {
      // top left, middle, right
      // center left, right
      // bottom left, middle, right

      row = [
        [w_side, h_1fourth],
        [w_center, h_1fourth],
        [w_side, h_1fourth],
      ];
      var centerRow = [
        [w / 2, h_center],
        [w / 2, h_center],
      ];

      mGrid.add(row as Array<Array<Number> >);
      mGrid.add(centerRow as Array<Array<Number> >);
      mGrid.add(row as Array<Array<Number> >);
    } else if (mFieldLayout == FL6SSFields) {
      var w_1third = w / 3;
      var w_1thirdMiddle = w - 2 * w_1third;
      // top left, middle,  right
      // bottom left, middle, right
      row = [
        [w_1third, h_halve],
        [w_1thirdMiddle, h_halve],
        [w_1third, h_halve],
      ];
      mGrid.add(row as Array<Array<Number> >);
      mGrid.add(row as Array<Array<Number> >);
    } else if (mFieldLayout == FL8SSFields) {
      var w_1fourth = w / 4;
      // top left, middle, middle, right
      // bottom left, middle, middle, right
      row = [
        [w_1fourth, h_halve],
        [w_1fourth, h_halve],
        [w_1fourth, h_halve],
        [w_1fourth, h_halve],
      ];
      mGrid.add(row as Array<Array<Number> >);
      mGrid.add(row as Array<Array<Number> >);
    } else if (mFieldLayout == FL6Fields) {
      // top left, middle, right
      // bottom left, middle, right
      row = [
        [w_side, h_halve],
        [w_center, h_halve],
        [w_side, h_halve],
      ];
      mGrid.add(row as Array<Array<Number> >);
      mGrid.add(row as Array<Array<Number> >);
    } else if (mFieldLayout == FL4Fields) {
      // top left, right
      // bottem left, right
      var w_halve = w / 2;
      row = [
        [w_halve, h_halve],
        [w_halve, h_halve],
      ];
      mGrid.add(row as Array<Array<Number> >);
      mGrid.add(row as Array<Array<Number> >);
    }
  }

  function compute(info as Activity.Info) as Void {
    mMetrics.compute(info);
    mCurrentLocation.onCompute(info);
    mDayLiteTime = isAtDaylightTime(Time.now(), true);

    mPaused = false;
    if (info has :timerState) {
      mPaused =
        info.timerState == Activity.TIMER_STATE_PAUSED or
        info.timerState == Activity.TIMER_STATE_OFF;
    }

    if (mPaused) {
      mActivityStartCountdown = 5;
      mZenCountdown = $.gZenCountdown;
    } else {
      if (mActivityStartCountdown >= 0) {
        mActivityStartCountdown--;
      }
      if (mZenCountdown >= 0) {
        mZenCountdown--;
      }
    }
    // mZenMode set in layout event. Hide details yes/no
    // So works only if one metrics field is on screen
    if (mZenMode == ZMOn) {
      mZenHideDetails = true;
    } else if (mZenMode == ZMOff) {
      mZenHideDetails = false;
    } else if (mZenMode == ZMWhenMoving) {
      // mZenActive when not paused and countdown not bewteen 0 and $.gZenCountdown.
      mZenHideDetails =
        !mPaused && (mZenCountdown <= 0 || mZenCountdown >= $.gZenCountdown);
    }

    var power = mMetrics.getPower();
    var perc = percentageOf(power, 0, $.gTargetFtp);
    mHiitt.compute(info, perc, power);

    if (power > 0.0) {
      mPowerFallbackCountdown = $.gPowerCountdownToFallBack;
    } else if (mPowerFallbackCountdown > 0) {
      mPowerFallbackCountdown--;
    }
    var cadence = mMetrics.getCadence();
    if (cadence > 0.0) {
      mCadenceFallbackCountdown = $.gCadenceCountdownToFallBack;
    } else if (mCadenceFallbackCountdown > 0) {
      mCadenceFallbackCountdown--;
    }

    // @@TEST
    // var tss = mMetrics.getTrainingStressScore();
    // var ifactor = mMetrics.getIntensityFactor();
    // var np = mMetrics.getNormalizedPower();
    // var tt = mMetrics.getTimerTime();
    // var timerTime = millisecondsToShortTimeString(tt, "{h}.{m}:{s}");
    // System.println("tt " + timerTime + " tt " + tt + "np " + np + " if " + ifactor + " tss " + tss);
  }

  function onUpdate(dc as Dc) as Void {
    if ($.gExitedMenu) {
      // fix for leaving menu, draw complete screen, large field
      dc.clearClip();
      $.gExitedMenu = false;
    }

    var hasGraphicFields =
      $.gShow_graphic_fields &&
      mBarPosition != BPOff &&
      $.gGraphic_fields.size() > 0;

    mBackgroundColor = getBackgroundColor();
    dc.setColor(mBackgroundColor, mBackgroundColor);
    dc.clear();

    mFontColor = Graphics.COLOR_BLACK;
    mDecimalsColor = mDecimalsColorDay;
    mUnitsColor = mUnitsColorDay;
    mIconColor = mIconColorDay;
    var barColor = mBarColorDay;
    var barDividerColor = mBackgroundColor;
    mBackgroundIsWhite = true;
    if (mBackgroundColor == Graphics.COLOR_BLACK) {
      mBackgroundIsWhite = false;
      mFontColor = Graphics.COLOR_WHITE;
      mDecimalsColor = mDecimalsColorNight;
      mUnitsColor = mUnitsColorNight;
      mIconColor = mIconColorNight;
      barColor = mBarColorNight;
    }
    dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);

    // top left, middle, right
    // centerleft, middle, right
    // bottom left, middle, right
    // !! Less nested function, less stack -> no stack overflow crash :-(
    // showGrid(dc);
    var showDemoField = $.gDemoFieldsRoundTrip > 0;
    if (showDemoField) {
      mDemoFt = getNextDemoFieldType(mDemoFt);
      showDemoField = mDemoFt != FTUnknown;
    } else {
      mDemoFields_FieldIndex = $.FieldTypeCount;
    }

    var y = 0;
    if (hasGraphicFields && mBarPosition == BPTop) {
      // Reserve space for the graphic bar
      y = mGraphicFieldHeight;
    }
    // @@ TEST, refactor
    mDrawBackgroundHiittIcon = false;
    var vo2maxHiitt = 0;
    switch ($.gVo2MaxBackGround) {
      case Vo2BgOff:
        break;
      case Vo2BgOn:
        // show always, calculate always
        vo2maxHiitt = mHiitt.getVo2Max();
        if (vo2maxHiitt == 0) {
          vo2maxHiitt = mHiitt.getAverageHiitScore();
        }
        break;
      case Vo2BgHiitOnly:
        // Show only hiitt scores, but actual score when hiitt active
        if (mHiitt.isEnabled()) {
          vo2maxHiitt = mHiitt.getVo2Max();
        }
        if (vo2maxHiitt == 0) {
          vo2maxHiitt = mHiitt.getAverageHiitScore();
        }
        break;
      case Vo2BgHiit:
        // show only during Hiitt
        if (mHiitt.isEnabled()) {
          vo2maxHiitt = mHiitt.getVo2Max();
          if (vo2maxHiitt == 0) {
            vo2maxHiitt = mHiitt.getAverageHiitScore();
          }
        }
        break;
    }

    if (vo2maxHiitt > 7) {
      var vo2maxProfile = mHiitt.getProfileVo2Max();
      mDrawBackgroundHiittIcon = true;
      var percentile = mHiitt.getVo2MaxPercentile(vo2maxHiitt);
      var improving = 0;
      if (vo2maxHiitt < vo2maxProfile) {
        improving = -1;
      } else if (vo2maxHiitt > 0 && vo2maxHiitt > vo2maxProfile) {
        improving = 1;
      }
      drawHiitIcon(
        dc,
        0,
        0,
        dc.getWidth(),
        dc.getHeight(),
        getIconColorRedToGreen(percentageOf(percentile, 0, 100), true),
        0,
        improving
      );
    }

    // Note, index 0 is field layout
    var f = 1;
    var rowCount = mGrid.size();
    for (var r = 0; r < rowCount; r++) {
      var row = mGrid[r];
      var cellCount = row.size();
      var x = 0;
      var h = 0;
      for (var c = 0; c < cellCount; c++) {
        // cell contains [w,h]
        var cell = row[c]; // as Array<Number>;

        var ft = FTUnknown;
        if (f < mFields.size()) {
          if (showDemoField) {
            ft = mDemoFt as FieldType;
          } else {
            ft = mFields[f] as FieldType;
          }
        }
        var fi = getFieldInfo(ft, f);

        // If field not available, get fallback field
        var fbProcessed = [] as Array<FieldType>;
        while (!fi.available) {
          var fb = getFallbackField(fi.type);
          if (fb == FTUnknown || fbProcessed.indexOf(fb) > -1) {
            fi.available = true;
          } else {
            fbProcessed.add(fb);
            fi = getFieldInfo(fb, f);
          }
        }

        // Focus on field info, when they are close or above target (or close or under target low).
        // https://www.perplexity.ai: How to calculate how close in percentage a value is to a lower bound?
        var colorPerc = Graphics.COLOR_LT_GRAY;
        var focusPerc = 0;
        var hasUpper = false;
        var hasLower = false;
        if (
          $.gFocusField != FocusOff &&
          fi.rawValue > 0 &&
          (fi.maxValue > 0 || fi.minValue > 0)
        ) {
          if (fi.maxValue > 0 && fi.minValue <= 0) {
            // 100% if close to upperbound (ignore lowerbound)
            focusPerc = percentageOf(fi.rawValue, 0, fi.maxValue);
            hasUpper = true;
          } else if (
            fi.maxValue > 0 &&
            fi.minValue > 0 &&
            fi.maxValue > fi.minValue
          ) {
            // 0% if close to lowerbound and 100% if close to upperbound
            focusPerc = percentageOf(fi.rawValue, fi.minValue, fi.maxValue);
            // focusPerc = percentageOf(
            //   fi.rawValue - fi.minValue,
            //   fi.maxValue - fi.minValue
            // );
            hasUpper = true;
            hasLower = true;
          } else if (fi.maxValue <= 0 && fi.minValue > 0) {
            focusPerc = percentageOf(fi.rawValue - fi.minValue, 0, fi.minValue);
            hasLower = true;
          }

          System.println([
            "focusfield ",
            focusPerc,
            fi.rawValue,
            fi.minValue,
            fi.maxValue,
            fi.title,
          ]);

          if (hasUpper && focusPerc > $.gFocusPerc) {
            dc.setPenWidth($.gFocusBorder);
            if ($.gFocusField == FocusColor) {
              System.println([
                "focusfield high",
                focusPerc,
                fi.rawValue,
                fi.minValue,
                fi.maxValue,
                fi.title,
              ]);
              colorPerc = getIconColorGreenToRed2(focusPerc, true);
            }
          } else if (hasLower && focusPerc < 100 - $.gFocusPerc) {
            dc.setPenWidth($.gFocusBorder);
            if ($.gFocusField == FocusColor) {
              System.println([
                "focusfield low",
                100 - focusPerc,
                fi.rawValue,
                fi.minValue,
                fi.maxValue,
                fi.title,
              ]);
              colorPerc = getIconColorGreenToRed2(100 - focusPerc, true);
            }
          }
        }
        if (gShowGrid || (focusPerc > 0 && focusPerc > $.gFocusPerc)) {
          dc.setColor(colorPerc, Graphics.COLOR_TRANSPARENT);
          dc.drawRectangle(x, y, cell[0], cell[1]);
          dc.setPenWidth(1);
        }

        drawFieldBackground(dc, fi, x, y, cell[0], cell[1]);
        drawFieldInfo(dc, fi, x, y, cell[0], cell[1]);

        x = x + cell[0];
        h = cell[1];
        f = f + 1;
      }
      y = y + h;
    }

    if (hasGraphicFields) {
      // Draw on top or at bottom
      var eMaxWidth = dc.getWidth() - 2;
      var ey = 0;
      if (mBarPosition == BPBottom) {
        ey = dc.getHeight() - mGraphicFieldHeight;
      } else {
        ey = 0;
      }
      var tagX = 1;
      var divider = 0;
      for (var e = 0; e < $.gGraphic_fields.size(); e++) {
        var eft = $.gGraphic_fields[e] as FieldType;
        if (eft != FTUnknown) {
          if (divider > 1) {
            // Add divider
            ey = ey + 1;
          }
          divider++;
          var efi = getFieldInfo(eft, e);
          // Show label at start of line
          if (mPaused and efi.tag.length() > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
              tagX,
              ey,
              Graphics.FONT_XTINY,
              efi.tag,
              Graphics.TEXT_JUSTIFY_VCENTER | Graphics.TEXT_JUSTIFY_LEFT
            );
            tagX = tagX + dc.getTextDimensions(efi.tag, Graphics.FONT_XTINY)[0];
          }
          // @@ for hr zone. value 0 set bar to zone 1 to fill zone 0.
          // @@ todo, use hr value and see if zones match?
          // if (efi.type == FTHeartRateZone) {
          //   efi.rawValue = efi.rawValue + 1;
          // }
          var ePerc = $.percentageOf(efi.rawValue, 0, efi.maxValue);
          var eColor = barColor;
          if ($.gCreateColors) {
            eColor = $.percentageToColor(
              ePerc,
              255,
              $.PERC_COLORS_GREEN_RED,
              0
            );
          }
          if (efi.barReversed) {
            // Right to left
            drawPercentageLine(
              dc,
              1,
              ey,
              eMaxWidth,
              -1 * ePerc,
              mGraphicLineHeight,
              eColor
            );
          } else {
            // left to right
            drawPercentageLine(
              dc,
              1,
              ey,
              eMaxWidth,
              ePerc,
              mGraphicLineHeight,
              eColor
            );
          }
        }
        ey = ey + mGraphicLineHeight;
      }
      if ($.gGraphic_fields_zones > 0) {
        var zoneWidth = dc.getWidth() / $.gGraphic_fields_zones;
        var zoneY = dc.getHeight();
        for (var z = 1; z < $.gGraphic_fields_zones; z++) {
          dc.setColor(mBackgroundColor, Graphics.COLOR_TRANSPARENT);
          dc.setPenWidth(3);
          dc.drawLine(
            z * zoneWidth,
            zoneY,
            z * zoneWidth,
            zoneY - mGraphicFieldHeight
          );
          dc.setPenWidth(1);
        }
      }
    }

    // if ($.gDebug) {
    //   dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    //   var font = Graphics.FONT_SYSTEM_SMALL;
    //   var text = Lang.format("$1$x$2$ $3$", [
    //     dc.getWidth(),
    //     dc.getHeight(),
    //     mDisplaySize,
    //   ]);
    //   dc.drawText(
    //     dc.getWidth() / 2,
    //     dc.getHeight() / 2,
    //     font,
    //     text,
    //     Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    //   );
    // }
  }

  hidden function getNextDemoFieldType(ftCurrent as FieldType) as FieldType {
    // show this field x seconds
    if (mDemoFields_Counter == -1) {
      mDemoFields_Counter = $.gDemoFieldsWait;
    } else if ((ftCurrent as Number) == mDemoFields_FieldIndex) {
      mDemoFields_Counter = mDemoFields_Counter - 1;
      return ftCurrent;
    }

    // next ft
    mDemoFields_FieldIndex = mDemoFields_FieldIndex - 1;
    // if all fields processed, next roundtrip
    if (mDemoFields_FieldIndex < 0) {
      $.gDemoFieldsRoundTrip = $.gDemoFieldsRoundTrip - 1;
      mDemoFields_FieldIndex = $.FieldTypeCount;
    }

    // finish roundtrips
    if ($.gDemoFieldsRoundTrip == 0) {
      return FTUnknown;
    }

    // demo ft
    return mDemoFields_FieldIndex as FieldType;
  }

  function getFallbackField(fieldType as FieldType) as FieldType {
    var idx = fieldType as Number;

    if (idx >= $.gFallbackFields.size()) {
      return FTUnknown;
    }
    return $.gFallbackFields[idx] as FieldType;
  }

  function getFieldInfo(
    fieldType as FieldType,
    fieldIdx as Number
  ) as FieldInfo {
    var fi = new FieldInfo(fieldType, fieldIdx);
    var useColor =
      $.gShowColors || $.gUseColorFields.indexOf(fi.type as Number) > -1;
    // System.println($.gUseColorFields);
    // System.println([fi.type, useColor]);

    switch (fieldType) {
      case FTDistance:
        fi.title = "distance";
        var dist = mMetrics.getElapsedDistance();
        fi.value = getDistanceInMeterOrKm(dist).format(
          getFormatForMeterAndKm(dist)
        );
        if (mSmallField) {
          fi.text = fi.value;
          fi.units_side = getUnitsInMeterOrKm(dist);
        } else {
          fi.number = stringLeft(fi.value, ".", fi.value);
          fi.decimals = stringRight(fi.value, ".", "");
          fi.units = getUnitsInMeterOrKm(dist);
        }
        fi.rawValue = dist / 1000; // in km
        fi.maxValue = $.gTargetDistance; // in km
        if (
          $.gTargetDistanceUseRoute &&
          mMetrics.getDistanceToDestination() > 0
        ) {
          // Use total possible distance in km
          fi.maxValue = (dist + mMetrics.getDistanceToDestination()) / 1000;
        }
        // @@TEST
        // System.println([fi.maxValue, fi.rawValue]);
        if (fi.maxValue > 0) {
          fi.iconColor = getIconColor(useColor, fi.rawValue, fi.maxValue);
        }
        return fi;

      case FTDistanceNext:
        fi.title = "next";
        var distNext = mMetrics.getDistanceToNextPoint();
        fi.available = distNext > 0;
        fi.value = getDistanceInMeterOrKm(distNext).format(
          getFormatForMeterAndKm(distNext)
        );
        if (mSmallField) {
          fi.text = fi.value;
          fi.units_side = getUnitsInMeterOrKm(distNext);
        } else {
          fi.number = stringLeft(fi.value, ".", fi.value);
          fi.decimals = stringRight(fi.value, ".", "");
          fi.units = getUnitsInMeterOrKm(distNext);
        }
        return fi;

      case FTDistanceDest:
        fi.title = "dest";
        var distDest = mMetrics.getDistanceToDestination();
        fi.available = distDest > 0;
        fi.value = getDistanceInMeterOrKm(distDest).format(
          getFormatForMeterAndKm(distDest)
        );
        if (mSmallField) {
          fi.text = fi.value;
          fi.units_side = getUnitsInMeterOrKm(distDest);
        } else {
          fi.number = stringLeft(fi.value, ".", fi.value);
          fi.decimals = stringRight(fi.value, ".", "");
          fi.units = getUnitsInMeterOrKm(distDest);
        }
        return fi;

      case FTGrade:
        fi.title = "grade";
        var grade = mMetrics.getGrade();

        if (gGradeFallbackStart < $.gGradeFallbackEnd) {
          fi.available =
            grade <= $.gGradeFallbackStart or grade >= $.gGradeFallbackEnd;
        }

        fi.value = grade.format("%0.1f");
        if (mSmallField) {
          // fi.text = fi.value;
          fi.number = stringLeft(fi.value, ".", fi.value);
          fi.decimals = stringRight(fi.value, ".", "");
          fi.units_side = "%";
        } else {
          fi.units = "%";
          fi.number = stringLeft(fi.value, ".", fi.value);
          fi.decimals = stringRight(fi.value, ".", "");
        }
        var g = grade;
        if (grade < 0) {
          grade = grade * -1;
        }

        fi.rawValue = grade;
        fi.maxValue = $.gTargetGrade;
        fi.iconColor = getIconColor(useColor, grade, $.gTargetGrade);
        fi.iconParam = g;
        return fi;

      case FTClock:
        fi.title = "clock";
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        fi.text = Lang.format("$1$:$2$", [
          today.hour,
          today.min.format("%02d"),
        ]);
        fi.decimals = today.sec.format("%02d");
        fi.units = Lang.format("$1$ $2$ $3$", [
          today.day_of_week,
          today.day,
          today.month,
        ]);
        fi.iconParam = Time.now().value() * 1000; // to mmsec
        return fi;

      case FTAverageHeartRate:
      case FTHeartRate:
        var heartRate = mMetrics.getHeartRate();
        fi.title = "heartrate";
        fi.tag = "hr";
        fi.units = "bpm";
        if (
          (gShowAverageWhenPaused && mPaused) ||
          fieldType == FTAverageHeartRate
        ) {
          fi.title = "avg heartrate";
          heartRate = mMetrics.getAverageHeartRate();
          fi.iconParam = mMetrics.getHeartRateZone(true);
          fi.units = "~bpm";
        } else {
          fi.iconParam = mMetrics.getHeartRateZone(false);
        }
        fi.number = heartRate.format("%0d");
        fi.available = heartRate > 0;

        fi.rawValue = heartRate;
        fi.maxValue = $.gTargetHeartRate;
        fi.iconColor = getIconColor(useColor, heartRate, $.gTargetHeartRate);
        return fi;

      case FTAveragePower:
      case FTPower:
        var power = mMetrics.getPower();
        if (mMetrics.getHasFailingDualpower()) {
          fi.prefix = "2*";
        }
        fi.title =
          "power (" + mMetrics.getPowerPerSec().format("%0d") + " sec)";
        fi.units = "w";
        if (
          ($.gShowAverageWhenPaused && mPaused) ||
          fieldType == FTAveragePower
        ) {
          if ($.gShowNPasAverage && fieldType == FTPower) {
            fi.title = "normalized power";
            power = mMetrics.getNormalizedPower();
          } else {
            fi.title = "avg power";
            power = mMetrics.getAveragePower();
            fi.units = "~w";
          }
        }
        fi.number = power.format("%0d");
        // System.println("Power " + power + " mPowerFallbackCountdown " + mPowerFallbackCountdown);
        fi.available =
          power > 0 and
          (mPowerFallbackCountdown > 0 or $.gPowerCountdownToFallBack == 0);

        fi.rawValue = power;
        fi.maxValue = $.gTargetFtp;
        fi.iconColor = getIconColor(useColor, power, $.gTargetFtp);
        return fi;

      case FTBearing:
        fi.text = getCompassDirection(mMetrics.getBearing());
        return fi;

      case FTAverageSpeed:
      case FTSpeed:
        fi.title = "speed";
        fi.tag = "spd";
        fi.units = "km/h";
        var speed;
        if (
          (gShowAverageWhenPaused && mPaused) ||
          fieldType == FTAverageSpeed
        ) {
          fi.title = "avg speed";
          speed = mpsToKmPerHour(mMetrics.getAverageSpeed());
          fi.units = "~km/h";
        } else {
          speed = mpsToKmPerHour(mMetrics.getSpeed());
        }
        fi.value = speed.format("%0.1f");
        fi.number = stringLeft(fi.value, ".", fi.value);
        fi.decimals = stringRight(fi.value, ".", "");
        fi.iconColor = getIconColor(useColor, speed, $.gTargetSpeed);
        fi.rawValue = speed;
        fi.maxValue = $.gTargetSpeed;
        return fi;

      case FTAltitude:
        fi.title = "altitude";
        fi.units = "m";
        var altitude = mMetrics.getAltitude();

        if (gAltitudeFallbackStart < $.gAltitudeFallbackEnd) {
          fi.available =
            altitude <= $.gAltitudeFallbackStart or
            altitude >= $.gAltitudeFallbackEnd;
        }

        if (mpsToKmPerHour(mMetrics.getSpeed()) < 15) {
          fi.value = altitude.format("%0.2f");
        } else {
          fi.value = altitude.format("%0d");
        }

        if (mWideField) {
          fi.number = stringLeft(fi.value, ".", fi.value);
          fi.decimals = stringRight(fi.value, ".", "");
          fi.units_side = "m";
        } else {
          fi.number = stringLeft(fi.value, ".", fi.value);
          fi.decimals = stringRight(fi.value, ".", "");
        }

        if (altitude < 0) {
          altitude = altitude * -1;
        }
        fi.rawValue = altitude;
        fi.maxValue = $.gTargetAltitude;
        fi.iconColor = getIconColor(useColor, altitude, $.gTargetAltitude);

        var totalAsc = mMetrics.getTotalAscent();
        if (totalAsc > 0) {
          fi.text_botleft = "A " + totalAsc.format("%0.0f");
        }
        var totalDesc = mMetrics.getTotalDescent();
        if (totalDesc > 0) {
          fi.text_botright = "D " + totalDesc.format("%0.0f");
        }

        return fi;

      case FTPressureAtSea:
      case FTPressure:
        fi.title = "pressure";
        fi.units = "hPa";
        fi.value = mMetrics.getAmbientPressure().format("%0.2f");
        if (fieldType == FTPressureAtSea) {
          fi.title = "at sea";
          fi.value = mMetrics.getMeanSeaLevelPressure().format("%0.2f");
        }
        fi.number = stringLeft(fi.value, ".", fi.value);
        fi.decimals = stringRight(fi.value, ".", "");
        // TODO optional? --> use icon value
        fi.iconParam = mMetrics.getPressureTrend();
        return fi;

      case FTAverageCadence:
      case FTCadence:
        fi.title = "cadence";
        fi.tag = "cad";
        fi.units = "rpm";

        var cadence;
        if (
          (gShowAverageWhenPaused && mPaused) ||
          fieldType == FTAverageCadence
        ) {
          cadence = mMetrics.getAverageCadence();
          fi.units = "~rpm";
        } else {
          cadence = mMetrics.getCadence();
        }
        fi.number = cadence.format("%0d");
        if (mWideField) {
          fi.units_side = "rpm";
        }
        fi.available =
          mMetrics.getCadence() > 0 and
          (mCadenceFallbackCountdown > 0 or $.gCadenceCountdownToFallBack == 0);
        fi.iconColor = getIconColor(useColor, cadence, $.gTargetCadence);
        fi.rawValue = cadence;
        fi.maxValue = $.gTargetCadence;
        fi.minValue = $.gTargetCadenceLow;
        return fi;

      case FTHiit:
        // @@TODO refactor
        fi.available = false;
        if (!mHiitt.isEnabled()) {
          return fi;
        }
        // Force display hiit stats info
        fi.text = " ";
        // Hiit needs power data
        var nrHiit = mHiitt.getNumberOfHits();
        fi.available =
          nrHiit > 0 ||
          (mMetrics.getPower() > 0 and
            (mPowerFallbackCountdown > 0 or
              $.gPowerCountdownToFallBack == 0)) ||
          mHiitt.isDemoActive();
        if (!fi.available) {
          return fi;
        }

        fi.title = "hiit";
        var showHiittText = 1;
        var vo2max = mHiitt.getVo2Max();
        var recovery = mHiitt.getRecoveryElapsedSeconds();
        var percentile = 0;
        if (recovery > 0) {
          showHiittText = 0;
          fi.text = secondsToCompactTimeString(recovery, "({m}:{s})");
          if (!mDrawBackgroundHiittIcon && mHiitt.wasValidHiit()) {
            // fi.iconColor = COLOR_LT_BLUE;
            percentile = mHiitt.getVo2MaxPercentile(vo2max);
            fi.iconColor = getIconColorRedToGreen(
              percentageOf(percentile, 0, 100),
              useColor
            );
          }
          if (mHiitt.isStartOfRecovery(10)) {
            fi.decimals = "";
            // TODO display the latest score
            fi.text = vo2max.format("%0d");
            // Not showing on decimals
            vo2max = 0;
          }
        } else {
          var counter = mHiitt.getCounter();
          if (counter > 0) {
            showHiittText = 0;
            fi.text = "(" + counter.format("%01d") + ")";
          } else {
            var hiitElapsed = mHiitt.getElapsedSeconds();
            if (hiitElapsed > 0) {
              showHiittText = 0;
              fi.text = secondsToCompactTimeString(hiitElapsed, "({m}:{s})");
              if (!mDrawBackgroundHiittIcon && mHiitt.wasValidHiit()) {
                //fi.iconColor = Graphics.COLOR_GREEN;
                percentile = mHiitt.getVo2MaxPercentile(vo2max);
                fi.iconColor = getIconColorRedToGreen(
                  percentageOf(percentile, 0, 100),
                  useColor
                );
              }
            }
          }
        }
        if (vo2max > 30) {
          fi.decimals = vo2max.format("%0.0f");
        }

        // if (mPaused) {
        //   fi.decimals = "";
        // }
        fi.iconParam = showHiittText;

        if (nrHiit > 0) {
          fi.text_botleft = "H " + nrHiit.format("%0.0d");
        }

        var scores = mHiitt.getHitScores();
        if (scores.size() > 0) {
          var sCounter = 0;
          for (
            var sIdx = scores.size() - 1;
            sIdx >= 0 and sCounter < 4;
            sIdx--
          ) {
            var score = scores[sIdx] as Number;

            fi.text_botright = fi.text_botright + " " + score.format("%0d");
            sCounter++;
          }
          // if (mPaused) {
          //   // @@ Correction for the pause border
          //   fi.text_botright = fi.text_botright + " ";
          //   // Show last score
          //   // fi.text = (scores[scores.size() - 1] as Float).format("%0.0f");
          // }
        }
        fi.iconParam2 = 0;
        var vo2maxProfile = mHiitt.getProfileVo2Max();
        var vo2maxHiit = mHiitt.getVo2Max();
        if (mPaused && mHiitt.isActivityPaused()) {
          // when demo, hiitt is not paused
          fi.decimals = "";
          // Use all scores when pauzed
          vo2maxHiit = mHiitt.getAverageHiitScore();
          if (!mDrawBackgroundHiittIcon) {
            percentile = mHiitt.getVo2MaxPercentile(vo2maxHiit);
            var perc0 = percentageOf(percentile, 0, 100);
            fi.iconColor = getIconColorRedToGreen(perc0, useColor);
          }
        }
        //System.println(["hiit", vo2maxProfile, vo2maxHiit]);
        if (vo2maxProfile > 0 && vo2maxHiit > 0) {
          if (vo2maxHiit < vo2maxProfile) {
            fi.iconParam2 = -1;
          } else if (vo2maxHiit > 0 && vo2maxHiit > vo2maxProfile) {
            fi.iconParam2 = 1;
          }
        }
        return fi;

      case FTTimer:
        fi.title = "timer";
        fi.iconParam = mMetrics.getTimerTime();
        var timerTime = millisecondsToShortTimeString(
          fi.iconParam,
          "{h}.{m}:{s}"
        );
        fi.iconParam2 = $.convertToNumber(stringLeft(timerTime, ".", "0"), 0);
        fi.text = stringRight(timerTime, ".", timerTime);
        return fi;

      case FTTimeElapsed:
        fi.title = "elapsed";
        fi.iconParam = mMetrics.getElapsedTime();
        var elapsedTime = millisecondsToShortTimeString(
          fi.iconParam,
          "{h}.{m}:{s}"
        );
        fi.iconParam2 = $.convertToNumber(stringLeft(elapsedTime, ".", "0"), 0);
        fi.text = stringRight(elapsedTime, ".", elapsedTime);
        return fi;

      case FTGearCombo:
        fi.title = "gear combo";
        fi.available = mMetrics.getFrontDerailleurSize() > 0;
        fi.text =
          mMetrics.getFrontDerailleurSize().format("%0d") +
          ":" +
          mMetrics.getRearDerailleurSize().format("%0d");
        return fi;

      case FTPowerPerWeight:
        if (mMetrics.getHasFailingDualpower()) {
          fi.prefix = "2*";
        }
        var powerpw;
        if (gShowAverageWhenPaused && mPaused) {
          fi.title =
            "avg power (" +
            mMetrics.getPowerPerSec().format("%0d") +
            " sec) / kg";
          powerpw = mMetrics.getAveragePowerPerWeight();
          fi.units = "~w/kg";
        } else {
          fi.title =
            "power (" + mMetrics.getPowerPerSec().format("%0d") + " sec) / kg";
          powerpw = mMetrics.getPowerPerWeight();
          fi.units = "w/kg";
        }
        fi.value = powerpw.format("%0.1f");
        fi.number = $.stringLeft(fi.value, ".", fi.value);
        fi.decimals = $.stringRight(fi.value, ".", "");
        fi.available =
          powerpw > 0 and
          (mPowerFallbackCountdown > 0 or $.gPowerCountdownToFallBack == 0);
        fi.rawValue = mMetrics.getPower();
        fi.maxValue = $.gTargetFtp;
        return fi;

      case FTPowerBalance:
        var powerCheck;
        var pLeft = mMetrics.getPowerBalanceLeft();
        if (gShowAverageWhenPaused && mPaused) {
          fi.title = "avg power balance";
          pLeft = mMetrics.getAveragePowerBalanceLeft();
          powerCheck = mMetrics.getAveragePower();
        } else {
          fi.title = "power balance";
          powerCheck = mMetrics.getPower();
        }
        if (pLeft > 0 and pLeft < 100) {
          var pRight = 100 - (pLeft as Number);
          fi.text = Lang.format("$1$:$2$", [
            (pLeft as Number).format("%02d"),
            pRight.format("%02d"),
          ]);
        }
        fi.available =
          powerCheck > 0 and
          (mPowerFallbackCountdown > 0 or $.gPowerCountdownToFallBack == 0);
        return fi;

      case FTHeartRateZone:
        fi.tag = "hrz";
        var hrcheck;
        if (gShowAverageWhenPaused && mPaused) {
          fi.title = "avg heartrate zone";
          hrcheck = mMetrics.getAverageHeartRate();
        } else {
          fi.title = "heartrate zone";
          hrcheck = mMetrics.getHeartRate();
        }
        var hrz = mMetrics.getHeartRateZone(gShowAverageWhenPaused && mPaused);
        fi.available = hrcheck > 0;
        fi.text = hrz.format("%d");
        fi.rawValue = hrz;
        fi.maxValue = mMetrics.getMaxHeartRateZone();
        return fi;

      case FTGearIndex:
        fi.title = "gear index";
        fi.available = mMetrics.getFrontDerailleurSize() > 0;
        fi.text =
          mMetrics.getFrontDerailleurIndex().format("%0d") +
          "|" +
          mMetrics.getRearDerailleurIndex().format("%0d");
        return fi;
      // Average fields are handled in the specific non-average field
      case FTNormalizedPower:
        fi.tag = "np";
        var np = mMetrics.getNormalizedPower();
        fi.available = np > 0; // and (mPowerFallbackCountdown > 0 or $.gPowerCountdownToFallBack == 0);

        if (mMetrics.getHasFailingDualpower()) {
          fi.prefix = "2*";
        }
        fi.title = "normalized power";
        fi.units = "w";
        fi.number = np.format("%0d");
        fi.iconColor = getIconColor(useColor, np, $.gTargetFtp);
        fi.rawValue = np;
        fi.maxValue = $.gTargetFtp;
        return fi;

      case FTIntensityFactor:
        fi.title = "IF";
        fi.tag = "if";
        var ifactor = mMetrics.getIntensityFactor();
        fi.available = ifactor > 0;
        fi.number = ifactor.format("%0.2f");
        fi.rawValue = ifactor;
        fi.maxValue = $.gTargetIF;
        return fi;

      case FTTrainingStressScore:
        fi.title = "TSS";
        fi.tag = "tss";
        var tss = mMetrics.getTrainingStressScore();
        fi.available = tss > 0;
        fi.number = tss.format("%0.02f");
        fi.rawValue = tss;
        fi.maxValue = $.gTargetTSS;
        return fi;

      case FTCalories:
        fi.title = "calories";
        fi.tag = "cal";
        var calories = mMetrics.getCalories();
        fi.available = calories > 0;
        fi.number = calories.format("%0d");
        fi.rawValue = calories;
        fi.maxValue = $.gTargetCalories;
        return fi;

      case FTEta:
        fi.title = "eta";
        var estimatedDuration_a = mMetrics.getEstimatedDurationToDestination(
          $.gTargetDistance * 1000,
          $.gTargetDistanceUseRoute
        );
        fi.iconColor = mIconColor;
        fi.available = estimatedDuration_a > 0;

        var laterMoment = Time.now();
        if (fi.available) {
          fi.prefix = "~";
          laterMoment = laterMoment.add(new Time.Duration(estimatedDuration_a));
        }
        var laterDay = Gregorian.info(laterMoment, Time.FORMAT_MEDIUM);
        fi.text = Lang.format("$1$:$2$", [
          laterDay.hour,
          laterDay.min.format("%02d"),
        ]);
        fi.decimals = laterDay.sec.format("%02d");
        fi.units = Lang.format("$1$ $2$ $3$", [
          laterDay.day_of_week,
          laterDay.day,
          laterDay.month,
        ]);

        return fi;

      case FTEtr:
        fi.title = "etr";
        fi.prefix = "~";
        var estimatedDuration_r = mMetrics.getEstimatedDurationToDestination(
          $.gTargetDistance * 1000,
          $.gTargetDistanceUseRoute
        );
        fi.iconColor = mIconColor;
        fi.available = estimatedDuration_r > 0;
        if (fi.available) {
          if (estimatedDuration_r <= 60) {
            fi.text = estimatedDuration_r.format("%02d");
          } else {
            fi.text = $.secondsToHourMinutes(estimatedDuration_r);
            var secondsLeft = estimatedDuration_r.toNumber() % 60;
            fi.decimals = secondsLeft.format("%02d");
          }
        } else {
          fi.text = "--:--";
        }
        return fi;

      case FTVo2MaxHiit:
      case FTVo2MaxProfile:
        fi.available = false;
        fi.title = "vo2max";
        fi.units = "vo2";

        var vo2maxProfile0 = mHiitt.getProfileVo2Max();
        var vo2maxHiit0 = mHiitt.getAverageHiitScore();
        var percentile0 = 0;
        // TODO rolling vo2max
        // TODO percentile info etc.
        if (fieldType == FTVo2MaxHiit) {
          fi.available = vo2maxHiit0 > 7;
          if (!fi.available) {
            return fi;
          }
          fi.number = vo2maxHiit0.format("%0d");
          percentile0 = mHiitt.getVo2MaxPercentile(vo2maxHiit0);
          if (percentile0 > 0) {
            fi.text_botleft = percentile0.format("%0d") + "%";
          }
          if (vo2maxProfile0 > 0) {
            fi.text_botright = "prof: " + vo2maxProfile0.format("%0d");
          }
        } else {
          // FTVo2MaxProfile
          fi.available = vo2maxProfile0 > 0;
          if (!fi.available) {
            return fi;
          }
          fi.number = vo2maxProfile0.format("%0d");
          percentile0 = mHiitt.getVo2MaxPercentile(vo2maxProfile0);
          if (percentile0 > 0) {
            fi.text_botleft = percentile0.format("%0d") + "%";
          }
          if (vo2maxHiit0 > 7) {
            fi.text_botright = "hiit: " + vo2maxHiit0.format("%0d");
          }
        }
        fi.maxValue = 100;
        fi.rawValue = percentile0;
        fi.iconParam = 0;
        if (vo2maxHiit0 > 0 && vo2maxProfile0 > 0) {
          if (vo2maxHiit0 < vo2maxProfile0) {
            fi.iconParam = -1;
          } else if (vo2maxHiit0 > vo2maxProfile0) {
            fi.iconParam = 1;
          }
        }
        fi.iconColor = getIconColorRedToGreen(
          percentageOf(fi.rawValue, fi.minValue, fi.maxValue),
          useColor
        );
        return fi;
      case FTTime2SunUp:
      case FTTime2SunDown:
      case FTTime2SunUpDown:
      case FTTime2SunUpDownLoop:
        fi.text = "--:--";
        if (mSunrise == null || mSunset == null || mSunriseTomorrow == null) {
          fi.available = false;
          return fi;
        }
        fi.iconParam2 = 0;

        var t2next = 0;
        if (fieldType == FTTime2SunUp) {
          fi.title = "Sunrise in";
          fi.iconParam2 = 1;
          t2next = $.getSecondsToNext(Time.now(), mSunrise);
          // System.println(["FTTime2SunUp", t2next ]);
        } else if (fieldType == FTTime2SunDown) {
          fi.title = "Sunset in";
          fi.iconParam2 = -1;
          t2next = $.getSecondsToNext(Time.now(), mSunset);
        } else {
          var t2sunrise = $.getSecondsToNext(Time.now(), mSunrise);

          if (t2sunrise > 0) {
            // Sun is not rised yet.
            fi.title = "Sunrise in";
            fi.iconParam2 = 1;
            t2next = t2sunrise;
          } else if (t2sunrise <= 0) {
            // Sun is already rised. Sunset will be next.
            var t2sunset = $.getSecondsToNext(Time.now(), mSunset);
            if (t2sunset > 0) {
              fi.title = "Sunset in";
              fi.iconParam2 = -1;
              t2next = t2sunset;
            } else if (fieldType == FTTime2SunUpDownLoop) {
              // Sun already set, get sunset for tomorrow
              t2sunrise = $.getSecondsToNext(Time.now(), mSunriseTomorrow);
              fi.title = "Sunrise in";
              fi.iconParam2 = 1;
              t2next = t2sunrise;
            }
          }
          // System.println(["FTTime2Sun next", t2next ]);
        }

        // When target specified, then field availble when in range (x min before).
        fi.available =
          t2next > 0 &&
          ($.gTargetSunEventSec == 0 ||
            (t2next < $.gTargetSunEventSec && $.gTargetSunEventSec > 0));

        // System.println([
        //   "FTTime2Sun i.available",
        //   fi.available,
        //   t2next,
        //   $.gTargetSunEventSec,
        //   colorFactor,
        // ]);

        // Always show data, if no fallback field then still data to show
        if (t2next < 60) {
          fi.text = t2next.format("%02d");
        } else {
          fi.text = $.secondsToHourMinutes(t2next);
          var secondsLeftNext = t2next.toNumber() % 60;
          fi.decimals = secondsLeftNext.format("%02d");
        }
        if (useColor) {
          if ($.gCreateColors) {
            fi.iconColor = getSunColor(60);
          } else {
            fi.iconColor = Graphics.COLOR_YELLOW;
          }
        } else {
          fi.iconColor = mIconColor; // TODO fade to yellow?
        }
        fi.iconParam = t2next;

        return fi;
      case FTPerc2SunUpDown:
      case FTPerc2SunUpDownLoop:
        if (mSunrise == null || mSunset == null) {
          fi.text = "--";
          fi.available = false;
          return fi;
        }
        var now_sec = Time.now().value();
        var sr_sec = mSunrise.value();
        var ss_sec = mSunset.value();
        var srt_sec = mSunriseTomorrow.value();

        var t2nextEvent = 0;
        var percOfTime = 0;
        if (now_sec < sr_sec) {
          // Perc to sunrise @@TODO get sunset yesterday
          fi.title = "%->Sunrise";
          fi.tag = "night";
          fi.iconParam = -1;
          // approx hack
          var ssy_sec = ss_sec - 86400; // yesterday sunset ~ sunset min 1 day in seconds.
          // percent of nighttime
          percOfTime = 100 - $.percentageOf(now_sec, ssy_sec, sr_sec);
          t2nextEvent = $.getSecondsToNext(Time.now(), mSunrise);
          fi.available = true;
        } else if (now_sec < ss_sec) {
          // Perc to sunset (today) 0 - 100
          fi.title = "%->Sunset";
          fi.tag = "day";
          fi.iconParam = 1;
          // percent of day time
          percOfTime = 100 - $.percentageOf(now_sec, sr_sec, ss_sec);
          t2nextEvent = $.getSecondsToNext(Time.now(), mSunset);
          fi.available = true;
        } else if (fieldType == FTPerc2SunUpDownLoop) {
          // Perc to sunrise tomorrow
          fi.title = "%->Sunrise";
          fi.tag = "night";
          fi.iconParam = -1;
          // percent of nighttime
          percOfTime = 100 - $.percentageOf(now_sec, ss_sec, srt_sec);
          t2nextEvent = $.getSecondsToNext(Time.now(), mSunriseTomorrow);
          fi.available = true;
        }
        
        // TODO test getSunColor colors
        // mTestTick = mTestTick + 1;
        // percOfTime = percOfTime - mTestTick;

        // Will go from 0 - 100% when target (sunset/sunrise) reached
        fi.rawValue = 100 - percOfTime;
        fi.maxValue = 100;
        fi.barReversed = true;
        // Only icon
        // Day / night count down to 0%
        // fi.text = percOfTime.format("%0d");
        // fi.units = "%";

        // When paused, show time to next event, or when within target range.
        if (
          !mZenHideDetails ||
          (t2nextEvent < $.gTargetSunEventSec && $.gTargetSunEventSec > 0)
        ) {
          if (t2nextEvent < 60) {
            fi.text = t2nextEvent.format("%02d");
          } else {
            fi.text = $.secondsToHourMinutes(t2nextEvent);
            var secondsLeftNextEvent = t2nextEvent.toNumber() % 60;
            fi.decimals = secondsLeftNextEvent.format("%02d");
          }
        }

        if (useColor) {
          if ($.gCreateColors) {
            fi.iconColor = getSunColor(percOfTime);
          } else {
            fi.iconColor = Graphics.COLOR_YELLOW;
          }
        } else {
          fi.iconColor = mIconColor; // TODO fade to yellow?
        }
        // System.println([
        //   "FTTPerc2Sun percOfTime mDayLiteTime",
        //   percOfTime,
        //   mDayLiteTime,
        // ]);
        return fi;
    }

    return fi;
  }

  // Percent to sun event (sunrise/sunset) -> 100 to 0% when event reached.
  function getSunColor(percent as Number) as ColorType {
    var redFrom;
    var greenFrom;
    var blueFrom;
    var redTo;
    var greenTo;
    var blueTo;
    mDayLiteTime = false;
    if (mDayLiteTime) {
      // Yellow rgb(255, 255, 55) = rgb(186, 102, 6)
      redFrom = 255;
      greenFrom = 255;
      blueFrom = 55;
      redTo = 186;
      greenTo = 102;
      blueTo = 6;
    } else {
      // Orange rgb(250, 190, 55) = rgb(245, 205, 5)
      redFrom = 250;
      greenFrom = 190;
      blueFrom = 55;
      redTo = 245;
      greenTo = 205;
      blueTo = 100;
    }
    // System.println(["getSunColor", percent, mDayLiteTime]);

    // if (mBackgroundIsWhite) {
    return $.transitionFromTo(
      100,
      redFrom,
      greenFrom,
      blueFrom,
      redTo,
      greenTo,
      blueTo,
      percent
    );   
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
      drawGradeIcon(
        dc,
        x,
        y,
        width,
        height,
        fi.iconColor,
        fi.iconParam.toDouble()
      );
      return;
    }
    if (fi.type == FTClock || fi.type == FTTimeElapsed || fi.type == FTTimer) {
      drawElapsedTimeIcon(
        dc,
        x,
        y,
        width,
        height,
        mIconColor,
        fi.iconParam.toNumber(),
        fi.iconParam2.toNumber()
      );
      return;
    }
    if (
      fi.type == FTHeartRate ||
      fi.type == FTAverageHeartRate ||
      fi.type == FTHeartRateZone
    ) {
      drawHeartIcon(
        dc,
        x,
        y,
        width,
        height,
        fi.iconColor,
        fi.iconParam.toNumber()
      );
      return;
    }
    if (
      fi.type == FTPower ||
      fi.type == FTAveragePower ||
      fi.type == FTNormalizedPower
    ) {
      drawPowerIcon(dc, x, y, width, height, fi.iconColor);

      if ($.gShowPowerBattery) {
        drawPowerBatteryLevel(
          dc,
          x,
          y,
          30,
          10,
          mMetrics.getPowerBatteryLevel()
        );
      }
      return;
    }
    if (fi.type == FTBearing) {
      // @@ drawBearingIcon(dc, x, y, width, height, mIconColor);
      return;
    }
    if (fi.type == FTSpeed || fi.type == FTAverageSpeed) {
      drawSpeedIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTAltitude) {
      drawAltitudeIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTPressureAtSea) {
      drawPressureAtSeaIcon(
        dc,
        x,
        y,
        width,
        height,
        mIconColor,
        fi.iconParam.toNumber()
      );
      return;
    }
    if (fi.type == FTPressure) {
      drawPressureIcon(
        dc,
        x,
        y,
        width,
        height,
        mIconColor,
        fi.iconParam.toNumber()
      );
      return;
    }
    if (fi.type == FTCadence || fi.type == FTAverageCadence) {
      drawCadenceIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTHiit) {
      drawHiitIcon(
        dc,
        x,
        y,
        width,
        height,
        fi.iconColor,
        fi.iconParam,
        fi.iconParam2
      );
      return;
    }
    if (fi.type == FTGearCombo) {
      // @@ drawGearComboIcon(dc, x, y, width, height, mIconColor);

      if ($.gShowShiftingBattery) {
        drawPowerBatteryLevel(
          dc,
          x,
          y,
          30,
          10,
          mMetrics.getShiftingBatteryLevel()
        );
      }
      return;
    }
    if (fi.type == FTPowerPerWeight) {
      // @@ drawPowerPerWeightIcon(dc, x, y, width, height, mIconColor);
      return;
    }
    if (fi.type == FTPowerBalance) {
      // @@ drawPowerBalanceIcon(dc, x, y, width, height, mIconColor);
      return;
    }
    if (fi.type == FTEta) {
      drawETAETRIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTEtr) {
      drawETAETRIcon(dc, x, y, width, height, fi.iconColor);
      return;
    }
    if (fi.type == FTVo2MaxHiit || fi.type == FTVo2MaxProfile) {
      drawVo2MaxIcon(dc, x, y, width, height, fi.iconColor, fi.iconParam);
      return;
    }
    if (
      fi.type == FTTime2SunUp ||
      fi.type == FTTime2SunDown ||
      fi.type == FTTime2SunUpDown ||
      fi.type == FTTime2SunUpDownLoop
    ) {
      drawTime2SunIcon(
        dc,
        x,
        y,
        width,
        height,
        fi.iconColor,
        fi.iconParam.toNumber(),
        fi.iconParam2.toNumber()
      );
      return;
    }
    if (fi.type == FTPerc2SunUpDown || fi.type == FTPerc2SunUpDownLoop) {
      drawPerc2SunIcon(
        dc,
        x,
        y,
        width,
        height,
        fi.iconColor,
        fi.rawValue.toNumber(),
        fi.iconParam.toNumber()
      );
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
    // var value = fieldInfo.value;
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
    // var text_middletop = fieldInfo.text_middletop;

    var fieldWidth = width;
    var x_offset_left = 0;
    var x_offset_right = 0;
    if (mPaused) {
      switch (mFieldLayout) {
        case FL8Fields:
          if (
            fieldInfo.index == 1 ||
            fieldInfo.index == 5 ||
            fieldInfo.index == 8
          ) {
            x_offset_right = $.gPause_x_offset;
          } else if (
            fieldInfo.index == 1 ||
            fieldInfo.index == 4 ||
            fieldInfo.index == 6
          ) {
            x_offset_left = $.gPause_x_offset;
          }
          break;
        case FL6Fields:
        case FL6SSFields:
          if (fieldInfo.index == 3 || fieldInfo.index == 6) {
            x_offset_right = $.gPause_x_offset;
          } else if (fieldInfo.index == 1 || fieldInfo.index == 4) {
            x_offset_left = $.gPause_x_offset;
          }
          fieldWidth = width - 4; // TEST
          break;
        case FL4Fields:
          if (fieldInfo.index == 2 || fieldInfo.index == 4) {
            x_offset_right = $.gPause_x_offset;
          } else if (fieldInfo.index == 1 || fieldInfo.index == 3) {
            x_offset_left = $.gPause_x_offset;
          }
          break;
        case FL8SSFields:
          if (fieldInfo.index == 4 || fieldInfo.index == 8) {
            x_offset_right = $.gPause_x_offset;
          } else if (fieldInfo.index == 1 || fieldInfo.index == 5) {
            x_offset_left = $.gPause_x_offset;
          }
          break;
      }
    }

    // var hideDetails = false;
    if (fieldInfo.type != FTHiit) {
      // hideDetails = mZenHideDetails;
      // if (mZenMode == ZMOn) {
      //   hideDetails = true;
      // } else if (mZenMode == ZMOff) {
      //   hideDetails = false;
      // } else if (mZenMode == ZMWhenMoving) {
      //   // Hide details when not paused and countdown not bewteen 0 and $.gZenCountdown.
      //   hideDetails =
      //     !mPaused && (mZenCountdown <= 0 || mZenCountdown >= $.gZenCountdown);
      // }
      if (mZenHideDetails) {
        text_botleft = "";
        text_botright = "";
        units = "";
        units_side = "";
      }
    }

    // small fields, no units
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
      text_botright = "";
      text_botleft = "";
    }
    if (fieldWidth <= 70) {
      units = "";
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
      title = $.cropTextToFit(dc, title, fontPrefix, fieldWidth - 2);
      dc.drawText(
        x + 1,
        y,
        Graphics.FONT_SYSTEM_XTINY,
        title,
        Graphics.TEXT_JUSTIFY_LEFT
      );
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
        font =
          getMatchingFont(dc, mFonts, fieldWidth, height, number_or_text) as
          FontType;
        dims_number_or_text = dc.getTextDimensions(number_or_text, font);
      } else if (number.length() > 0) {
        number_or_text = number;
        font =
          getMatchingFont(
            dc,
            mFontsNumbers,
            fieldWidth,
            height,
            number_or_text
          ) as FontType;
        dims_number_or_text = dc.getTextDimensions(number_or_text, font);
      }

      // System.println([
      //         "field index",
      //         fieldInfo.index,
      //         $.getFieldTypeAsString(fieldInfo.type),
      //         number_or_text,
      //         decimals,
      //         "field width",
      //         fieldWidth,
      //         "height",
      //         height,
      //         "font",
      //         font,
      //         dims_number_or_text,
      //       ]);
      var fontDecimals = Graphics.FONT_SYSTEM_MEDIUM;
      if (decimals.length() > 0) {
        if (fieldWidth < 46) {
          fontDecimals = Graphics.FONT_SYSTEM_XTINY;
        } else if (fieldWidth < 100) {
          fontDecimals = Graphics.FONT_SYSTEM_TINY;
        } else if (fieldWidth < 150) {
          fontDecimals = Graphics.FONT_SYSTEM_SMALL;
        }
        // if (height < 100) {
        //   fontDecimals = Graphics.FONT_SYSTEM_SMALL;
        // } else if (height < 45) {
        //   fontDecimals = Graphics.FONT_SYSTEM_TINY;
        // }
        if (font == fontDecimals) {
          fontDecimals = Graphics.FONT_XTINY;
        }
        dims_decimals = dc.getTextDimensions(decimals, fontDecimals);
      }

      var xSplit = (
        x +
        (fieldWidth - dims_number_or_text[0] - dims_decimals[0]) / 2 +
        dims_number_or_text[0]
      ).toNumber();
      //var yBase = y + (height - dims_number_or_text[1]) / 2;
      var yBase = y + height / 2 - dims_number_or_text[1] / 2; // @@ TODO center text/values and rest valign center?
      // dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_GREEN);
      dc.drawText(
        xSplit,
        yBase + mYoffsetFix,
        font,
        number_or_text,
        Graphics.TEXT_JUSTIFY_RIGHT
      );

      // System.print(number_or_text);
      // System.println(dims_number_or_text);
      // if (text_middletop.length() > 0) {
      //   // @@ TODO get right font
      //   var fontTextMiddleTop = fontDecimals;
      //   var dims_middleTop = dc.getTextDimensions(text_middletop, fontTextMiddleTop);
      //   var xMiddleTop = x + width / 2;
      //   var yMiddleTop = y + dims_middleTop[0];
      //   if (mReverseColor) {
      //     dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      //   } else {
      //     dc.setColor(mDecimalsColor, Graphics.COLOR_TRANSPARENT);
      //   }
      //   dc.drawText(xMiddleTop, yMiddleTop, fontTextMiddleTop, text_middletop, Graphics.TEXT_JUSTIFY_CENTER);
      // }

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
        dc.drawText(
          xSplit,
          yDec,
          fontDecimals,
          decimals,
          Graphics.TEXT_JUSTIFY_LEFT
        );
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
        if (xUnits + dims_units[0] > fieldWidth) {
          // Units on center bottom when small field (@@ +1 fix for edge 1040
          // display not same as on simulator)
          xUnits = x + fieldWidth / 2 - dims_units[0] / 2;
          yUnits =
            yBase + dims_number_or_text[1] - Graphics.getFontDescent(font) + 1; // not needed on device - Graphics.getFontDescent(fontUnits)
        }
        dc.drawText(
          xUnits,
          yUnits,
          fontUnits,
          units,
          Graphics.TEXT_JUSTIFY_LEFT
        );
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
        var xUnits = x + fieldWidth - 1;
        dc.drawText(
          xUnits,
          yUnits,
          fontUnits,
          units_side,
          Graphics.TEXT_JUSTIFY_RIGHT
        );
      }

      if (text_botright.length() > 0) {
        dc.setColor(mDecimalsColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
          x + fieldWidth - 1 - x_offset_right,
          y + height - dc.getFontHeight(font_text_bot),
          font_text_bot,
          text_botright,
          Graphics.TEXT_JUSTIFY_RIGHT
        );
      }
      if (text_botleft.length() > 0) {
        dc.setColor(mDecimalsColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
          x + 1 + x_offset_left,
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
        dc.drawText(
          xPrefix,
          yPrefix,
          fontPrefix,
          prefix,
          Graphics.TEXT_JUSTIFY_LEFT
        );
      }
    }

    if (text_middleleft.length() > 0) {
      dc.drawText(
        x + 1 + x_offset_left,
        y + height / 4,
        Graphics.FONT_SYSTEM_TINY,
        text_middleleft,
        Graphics.TEXT_JUSTIFY_LEFT
      );
    }
    if (text_middleright.length() > 0) {
      dc.drawText(
        x + fieldWidth - 1 - x_offset_right,
        y + height / 4,
        Graphics.FONT_SYSTEM_TINY,
        text_middleright,
        Graphics.TEXT_JUSTIFY_RIGHT
      );
    }
  }

  hidden function getIconColor(
    useColor as Boolean,
    value as Numeric,
    maxValue as Numeric
  ) as Graphics.ColorType {
    mReverseColor = false;
    if (useColor and $.gCreateColors) {
      var perc = percentageOf(value, 0, maxValue);
      var shade = 0;
      if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        shade = -30;
      } else {
        // mReverseColor = perc >= 165;
      }
      return percentageToColor(perc, 255, $.PERC_COLORS_SCHEME, shade);
    } else {
      return mIconColor;
    }
  }

  hidden function getIconColorGreenToRed(
    value as Numeric,
    maxValue as Numeric,
    useColor as Boolean
  ) as Graphics.ColorType {
    mReverseColor = false; // @@ TODO <-- refactor
    if (useColor and $.gCreateColors) {
      var perc = percentageOf(value, 0, maxValue);
      var shade = 10;
      if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        shade = -30;
      } else {
        // mReverseColor = perc >= 165;
      }
      return percentageToColor(perc, 255, $.PERC_COLORS_GREEN_TO_RED, shade);
    } else {
      return mIconColor;
    }
  }

  hidden function getIconColorGreenToRed2(
    perc as Numeric,
    useColor as Boolean
  ) as Graphics.ColorType {
    mReverseColor = false; // @@ TODO <-- refactor
    if (useColor and $.gCreateColors) {
      // var perc = percentageOf(value, maxValue);
      var shade = 10;
      if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        shade = -30;
      } else {
        // mReverseColor = perc >= 165;
      }
      return percentageToColor(perc, 255, $.PERC_COLORS_GREEN_TO_RED, shade);
    } else {
      return mIconColor;
    }
  }

  hidden function getIconColorRedToGreen(
    perc as Numeric,
    //maxValue as Numeric,
    useColor as Boolean
  ) as Graphics.ColorType {
    mReverseColor = false;
    if (useColor and $.gCreateColors) {
      // var perc = percentageOf(value, maxValue);
      var shade = 10;
      if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        shade = -30;
      } else {
        // mReverseColor = perc >= 165;
      }
      return percentageToColor(perc, 255, $.PERC_COLORS_RED_TO_GREEN, shade);
    } else {
      return mIconColor;
    }
  }

  hidden function checkReverseColor(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number
  ) as Void {
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
    if (!gShowIcon) {
      return;
    }

    // var r = (height / 3.85).toNumber();
    var r = (height / 5).toNumber();
    var x0 = (x + width / 2).toNumber();
    var y1 = (y + 1.5 * r).toNumber();
    var x1 = (x0 - 0.8 * r).toNumber();
    var x2 = (x1 + 1.6 * r).toNumber();

    var xc1 = pointOnCircle_x(x1, y1, r, 135);
    var yc1 = pointOnCircle_y(x1, y1, r, 135);
    var xc2 = pointOnCircle_x(x2, y1, r, 45);
    var yc2 = pointOnCircle_y(x2, y1, r, 45);
    // var y3 = (y + height - 0.5 * r).toNumber();
    var y3 = (y + height - r).toNumber();

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

    var zone = hrZone.format("%0d");
    var font =
      $.getMatchingFont(dc, mFontsNumbers, width, height, zone) as FontType;

    // hr zone
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      x + 1,
      y + height - dc.getFontHeight(font),
      font,
      zone,
      Graphics.TEXT_JUSTIFY_LEFT // | Graphics.TEXT_JUSTIFY_VCENTER
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
    if (!gShowIcon) {
      return;
    }

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
    if (!gShowIcon) {
      return;
    }

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
    if (!gShowIcon) {
      return;
    }

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

    dc.fillRectangle(x2, yc - my / 2, x3 - x2, my);

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
    if (!gShowIcon) {
      return;
    }

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
    if (!gShowIcon) {
      return;
    }

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
    if (!gShowIcon) {
      return;
    }

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
    batteryLevel as Number
  ) as Void {
    if (batteryLevel < 0) {
      return;
    }

    var topMargin = 2;
    var barWidth = 4;
    var barHeight = height - 2; // Inner height
    var barSpacing = 1;
    var startX = x + 2;

    // Filled color
    if (batteryLevel >= 3) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
    } else if (batteryLevel == 2) {
      dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
    } else {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
    }

    dc.setPenWidth(1);
    for (var i = 1; i <= 5; ++i) {
      var barX = startX + (i - 1) * (barWidth + barSpacing);
      if (i <= batteryLevel) {
        // dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        dc.fillRectangle(barX, y + topMargin, barWidth, barHeight);
      } else {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT); // Empty outline
        dc.drawRectangle(barX, y + topMargin, barWidth, barHeight);
      }
    }
  }

  hidden function drawHiitIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    showText as Numeric,
    improving as Numeric
  ) as Void {
    var x1 = x + width / 2;
    var y1 = y + height / 2;

    // dc.fillRectangle(x, y, width, height);

    var r = width / 2.5;
    if (width > height) {
      r = height / 2.5;
    }

    if (color != Graphics.COLOR_TRANSPARENT) {
      dc.setColor(color, Graphics.COLOR_TRANSPARENT);

      if (improving == 0) {
        dc.fillCircle(x1, y1, r);
      } else if (improving > 0) {
        var triangleUp =
          [
            [x1, y1 - r],
            [x1 - r, y1 + r],
            [x1 + r, y1 + r],
          ] as Array<Graphics.Point2D>;
        dc.fillPolygon(triangleUp);
      } else {
        var triangleDown =
          [
            [x1 - r, y1 - r],
            [x1 + r, y1 - r],
            [x1, y1 + r],
          ] as Array<Graphics.Point2D>;
        dc.fillPolygon(triangleDown);
      }
    }

    if (showText > 0) {
      // @@TODO draw very faint, hiit/vo2max text

      if (color == Graphics.COLOR_TRANSPARENT || color == mBackgroundColor) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(mBackgroundColor, Graphics.COLOR_TRANSPARENT);
      }

      // reversed..
      // if (color == Graphics.COLOR_TRANSPARENT || color == mBackgroundColor) {
      //   dc.setColor(mBackgroundColor, Graphics.COLOR_TRANSPARENT);
      // } else {
      //   dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      // }

      var text = "HIIT";
      var font = getMatchingFont(dc, mFonts, width, height, text) as FontType;
      dc.drawText(
        x1,
        y1,
        font,
        text,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
  }

  hidden function drawETAETRIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var r = width / 2.5;
    if (width > height) {
      r = height / 2.5;
    }
    var x1 = x + width / 2;
    var y1 = y + height / 2;

    dc.setPenWidth(5);
    setColorFillStroke(dc, color);
    dc.drawCircle(x1, y1, r);
    dc.drawCircle(x1, y1, r / 2);
    dc.drawCircle(x1, y1, r / 3);
    dc.setPenWidth(1);
  }

  hidden function drawVo2MaxIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    improving as Numeric
  ) as Void {
    setColorFillStroke(dc, color);

    var x1 = x + width / 2;
    var y1 = y + height / 2;
    var r = width / 2.5;
    if (width > height) {
      r = height / 2.5;
    }

    if (improving == 0) {
      dc.fillCircle(x1, y1, r);
    } else if (improving > 0) {
      var triangleUp =
        [
          [x1, y1 - r],
          [x1 - r, y1 + r],
          [x1 + r, y1 + r],
        ] as Array<Graphics.Point2D>;
      dc.fillPolygon(triangleUp);
    } else {
      var triangleDown =
        [
          [x1 - r, y1 - r],
          [x1 + r, y1 - r],
          [x1, y1 + r],
        ] as Array<Graphics.Point2D>;
      dc.fillPolygon(triangleDown);
    }
  }
  hidden function drawTime2SunIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    secondsRemaining as Number,
    eventType as Number
  ) as Void {
    // eventType 1 is sunrise, -1 sunset
    setColorFillStroke(dc, mIconColor);
    if (eventType > 0) {
      drawArrowUp(dc, x, y + 1, width / 5, height - 2);
    } else {
      drawArrowDown(dc, x, y + 1, width / 5, height - 2);
    }

    var x1 = x + width / 2;
    var y1 = y + height / 2;
    var r = width / 3; //2.5;
    if (width > height) {
      r = height / 3; //2.5;
    }

    setColorFillStroke(dc, color);
    dc.fillCircle(x1, y1, r);

    if (eventType > 0) {
      var triangleUp =
        [
          [x1, y1 - r],
          [x1 - r, y1 + r],
          [x1 + r, y1 + r],
        ] as Array<Graphics.Point2D>;
      dc.fillPolygon(triangleUp);
    } else if (eventType < 0) {
      var triangleDown =
        [
          [x1 - r, y1 - r],
          [x1 + r, y1 - r],
          [x1, y1 + r],
        ] as Array<Graphics.Point2D>;
      dc.fillPolygon(triangleDown);
    }
  }

  hidden function drawPerc2SunIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    percOfToEvent as Number,
    eventType as Number
  ) as Void {
    // eventType 1 is day, -1 night
    setColorFillStroke(dc, color);

    var x1 = x + width / 2;
    var y1 = y + height / 2;
    var r = width / 2.5;
    if (width > height) {
      r = height / 2.5;
    }
    r = r.toNumber();

    // System.println(["drawPerc2SunIcon eventType", eventType]);
    if (eventType > 0) {
      // The sun
      dc.fillCircle(x1, y1, r);
      // Remove perc of it
      setColorFillStroke(dc, mBackgroundColor);
      $.fillPercentageCircle(dc, x1, y1, r, percOfToEvent);
    } else if (eventType < 0) {
      // The moon
      // Already drawn at the end
      // Add perc of it
      $.fillPercentageCircle(dc, x1, y1, r, percOfToEvent);
    }

    setColorFillStroke(dc, mIconColor);
    // dc.setPenWidth(2);
    dc.drawCircle(x1, y1, r);
    // dc.setPenWidth(1);

    // System.println(["Draw", percOfToEvent, mZenHideDetails]);

    // Not showing perc, but time to next event. Perc is in the circle
    // if (mZenHideDetails) {
    //   return;
    // }
    // // Perc of day/night time 100 -> 0
    // var perc = (100 - percOfToEvent).format("%0d");
    // var font = $.getMatchingFont(dc, mFontsNumbers, width, height, perc) as FontType;

    // dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);
    // dc.drawText(x1, y1, font, perc, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
  }

  hidden function drawCadenceIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    if (!gShowIcon) {
      return;
    }

    var r = width / 2.5;
    if (width > height) {
      r = height / 2.5;
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
    timeInMilliSeconds as Number,
    hourPart as Number
  ) as Void {
    if (!gShowIcon) {
      return;
    }

    var r = width / 2.5;
    if (width > height) {
      r = height / 2.5;
    }
    r = r.toNumber();
    var x1 = x + width / 2;
    var y1 = y + height / 2;

    dc.setPenWidth(5);
    setColorFillStroke(dc, color);
    dc.drawCircle(x1, y1, r);

    dc.drawLine(x1, y1 - r, x1, y1 - r - 1);

    var hours = (timeInMilliSeconds / (1000.0 * 60 * 60)).toNumber() % 24;
    var minutes = (timeInMilliSeconds / (1000.0 * 60.0)).toNumber() % 60;
    var seconds = (timeInMilliSeconds / 1000.0).toNumber() % 60;

    // hour angle = 30 * hour + 0.5 * minute + 0.5 / 60 X second
    var hDeg =
      ((hours * 30 + 0.5 * minutes + (0.5 / 60) * seconds).toNumber() % 360) +
      90;
    // minute angle = 6 * minute + 0.1 * second
    var mDeg = (minutes * 6 + 0.1 * seconds - 90).toNumber() % 360;
    // Second angle = 6 * second (Each minute is 6 degrees; each second adds 0.1 degrees.)
    // var sDeg = ((seconds * 6).toNumber() % 360) - 30; // - 24;

    // System.println(["h,m,s:", hDeg, mDeg]); // , sDeg]);

    var xhour = pointOnCircle_x(x1, y1, r, hDeg);
    var yhour = pointOnCircle_y(x1, y1, r, hDeg);

    var xminute = pointOnCircle_x(x1, y1, r - 2, mDeg);
    var yminute = pointOnCircle_y(x1, y1, r - 2, mDeg);

    // var xsecond = pointOnCircle_x(x1, y1, r - 3, sDeg);
    // var ysecond = pointOnCircle_y(x1, y1, r - 3, sDeg);

    dc.drawLine(x1, y1, xhour, yhour);
    dc.setPenWidth(2);
    dc.drawLine(x1, y1, xminute, yminute);
    dc.setPenWidth(1);
    // dc.drawLine(x1, y1, xsecond, ysecond);
    // dc.setPenWidth(1);

    if (hourPart > 0) {
      var hourString = hourPart.format("%0d");
      var font =
        $.getMatchingFont(dc, mFontsNumbers, width, height, hourString) as
        FontType;
      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        x + 1,
        y + height - dc.getFontHeight(font),
        font,
        hourString,
        Graphics.TEXT_JUSTIFY_LEFT // | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
  }

  hidden function drawAltitudeIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    if (!gShowIcon) {
      return;
    }

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

  hidden function drawPressureAtSeaIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    trend as Number
  ) as Void {
    if (!gShowIcon) {
      return;
    }

    setColorFillStroke(dc, mIconColor);
    if (trend > 0) {
      drawArrowUp(dc, x, y + 1, width / 5, height - 2);
    } else if (trend < 0) {
      drawArrowDown(dc, x, y + 1, width / 5, height - 2);
    }

    var m0 = height / 8;

    var m = (height / 5).toNumber();
    var d = (width / 6).toNumber();
    var x1 = x + d;
    var y1 = y + m * 2;
    var x5 = (x1 + 4 * d).toNumber();

    var y2 = y1 + m;

    var x2 = x1 + d;
    var x3 = x2 + d;
    var x4 = x3 + d;

    var y3 = y + m * 3;
    setColorFillStroke(dc, color);
    dc.drawLine(x1 - m0, y1, x5 + m0, y1);

    dc.fillPolygon(
      [
        [x1, y1],
        [x2, y2],
        [x3, y1],
        [x4, y2],
        [x5, y1],
      ] as Array<Point2D>
    );

    dc.drawLine(x1 - m0, y3, x5 + m0, y3);

    // if (trend != 0) {
    //   var font;
    //   var trendIndicator;

    //   dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    //   if (trend < 0) {
    //     trendIndicator = "-";
    //   } else {
    //     trendIndicator = "+";
    //   }
    //   font =
    //     $.getMatchingFont(dc, mFontsNumbers, width, height, trendIndicator) as
    //     FontType;

    //   dc.drawText(
    //     x + 1,
    //     y + height - dc.getFontHeight(font),
    //     font,
    //     trendIndicator,
    //     Graphics.TEXT_JUSTIFY_LEFT // | Graphics.TEXT_JUSTIFY_VCENTER
    //   );
    // }
  }

  hidden function drawPressureIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType,
    trend as Number
  ) as Void {
    if (!gShowIcon) {
      return;
    }

    setColorFillStroke(dc, mIconColor);
    if (trend > 0) {
      drawArrowUp(dc, x, y + 1, width / 5, height - 2);
    } else if (trend < 0) {
      drawArrowDown(dc, x, y + 1, width / 5, height - 2);
    }

    var m0 = height / 8;

    var m = (height / 5).toNumber();
    var d = (width / 6).toNumber();
    var x1 = x + d;
    var y1 = y + m * 2;
    var x5 = (x1 + 4 * d).toNumber();

    var y2 = y1 + m;

    var x2 = x1 + d;
    var x3 = x2 + d;
    var x4 = x3 + d;

    setColorFillStroke(dc, color);
    dc.drawLine(x1 - m0, y1, x5 + m0, y1);

    dc.fillPolygon(
      [
        [x1, y1],
        [x2, y2],
        [x3, y1],
        [x4, y2],
        [x5, y1],
      ] as Array<Point2D>
    );

    // if (trend != 0) {
    //   var font;
    //   var trendIndicator;

    //   dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    //   if (trend < 0) {
    //     trendIndicator = "-";
    //   } else {
    //     trendIndicator = "+";
    //   }
    //   font =
    //     $.getMatchingFont(dc, mFontsNumbers, width, height, trendIndicator) as
    //     FontType;

    //   dc.drawText(
    //     x + 1,
    //     y + height - dc.getFontHeight(font),
    //     font,
    //     trendIndicator,
    //     Graphics.TEXT_JUSTIFY_LEFT // | Graphics.TEXT_JUSTIFY_VCENTER
    //   );
    // }
  }

  hidden function showDebugValues(dc as Dc) as Void {
    var font = Graphics.FONT_SMALL;
    var x = 1;
    var y = 1;
    var l = dc.getFontHeight(font);

    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format("Alt: $1$", [mMetrics.getAltitude()]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
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
    dc.drawText(
      x,
      y,
      Graphics.FONT_SMALL,
      Lang.format("Grade: $1$", [grades]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
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
      Lang.format(".. Battery level: $1$", [
        mMetrics.getPowerBatteryLevel().format("%0d"),
      ]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Battery voltage: $1$", [
        mMetrics.getPowerBatteryVoltage().format("%0.0f"),
      ]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    var operatingTimeInSeconds = mMetrics.getPowerOperatingTimeInSeconds();
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format(".. Oper seconds: $1$", [
        operatingTimeInSeconds.format("%0d"),
      ]),
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
        vo2max.format("%0d"),
      ]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }

  function drawArrowUp(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number
  ) as Void {
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

  function drawArrowDown(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number
  ) as Void {
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

  hidden function targetDataAvailable(eft as FieldType) as Boolean {
    if (eft == FTDistance) {
      return (
        $.gTargetDistance > 0 ||
        ($.gTargetDistanceUseRoute && mMetrics.getDistanceToDestination() > 0)
      );
    }
    // @@ TODO, calc during activity
    return true;
  }
}
