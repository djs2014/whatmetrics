import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Time;
using Toybox.Time.Gregorian;

class whatmetricsView extends WatchUi.DataField {
  hidden var mFieldSize as String;
  hidden var mDebug as Boolean = true;
  hidden var mPaused as Boolean = true;

  // [[w,h],[w,h],[w,h]]
  hidden var mGrid as Array<Array<Array<Number> > > = [] as Array<Array<Array<Number> > >;
  hidden var mFontColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mReverseColor as Boolean = false;
  hidden var mDecimalsColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mUnitsColor as Graphics.ColorType = Graphics.COLOR_BLACK;
  hidden var mIconColor as Graphics.ColorType = Graphics.COLOR_BLACK;
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

  function initialize() {
    DataField.initialize();
    mFieldSize = "?x?";

    checkFeatures();
    mDecimalsColor = Graphics.createColor(180, 50, 50, 50);
    mUnitsColor = Graphics.createColor(180, 100, 100, 100);
    mIconColor = Graphics.createColor(255, 220, 220, 220);
  }

  function onLayout(dc as Dc) as Void {
    var h = dc.getHeight();
    var w = dc.getWidth();
    mFieldSize = Lang.format("$1$x$2$", [dc.getHeight(), dc.getWidth()]);

    mGrid = [] as Array<Array<Array<Number> > >;

    var w_2fifth = (w * 2) / 5;
    var w_center = w - 2 * w_2fifth;
    var h_1fourth = h / 4;
    var h_center = h - 2 * h_1fourth;

    var row = [
      [w_2fifth, h_1fourth],
      [w_center, h_1fourth],
      [w_2fifth, h_1fourth],
    ];
    mGrid.add(row as Array<Array<Number> >);

    row = [
      [w / 2, h_center],
      [w / 2, h_center],
    ];
    mGrid.add(row as Array<Array<Number> >);

    row = [
      [w_2fifth, h_1fourth],
      [w_center, h_1fourth],
      [w_2fifth, h_1fourth],
    ];
    mGrid.add(row as Array<Array<Number> >);
  }

  function compute(info as Activity.Info) as Void {
    gMetrics.compute(info);
    // @@
    mPaused = gHiitt.isActivityPaused();

    var power = gMetrics.getPower();
    var perc = percentageOf(power, gTargetFtp);
    gHiitt.compute(info, perc);
  }

  function onUpdate(dc as Dc) as Void {
    dc.setColor(getBackgroundColor(), getBackgroundColor());
    dc.clear();

    mFontColor = Graphics.COLOR_BLACK;
    if (getBackgroundColor() == Graphics.COLOR_BLACK) {
      mFontColor = Graphics.COLOR_WHITE;
    }
    dc.setColor(mFontColor, Graphics.COLOR_TRANSPARENT);

    if (gDebug) {
      showDebugValues(dc);
      return;
    }

    // top left, middle, right
    // centerleft, middle, right
    // bottom left, middle, right
    showGrid(dc);
    return;

    // grid,
    // circles

    // units - small font rotate?

    // var m = 0;
    // var x = m;
    // var y = m;
    // var width = dc.getWidth();
    // var height = dc.getHeight();
    // var penWidth = 5;
    // dc.setPenWidth(penWidth);
    // dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    // dc.drawRoundedRectangle(x, y, width - 2 * m, height - 2 * m, penWidth);
    // dc.setPenWidth(1);

    // var text = gMetrics.getHeartRate().format("%0d");
    // var font = Graphics.FONT_NUMBER_THAI_HOT;
    // var l = dc.getFontHeight(font);
    // // var w = dc.getTextWidthInPixels(text, font);
    // var w = dc.getWidth() / 3;
    // // .... ... .... small
    // // .....  ..... big font
    // // .... ... .... small

    // var corner = l / 4;
    // var percHr = percentageOf(gMetrics.getHeartRate(), gTargetHeartRate);
    // setColorByPerc(dc, percHr);
    // dc.fillRoundedRectangle(x,y, w, l, corner);
    // dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    // dc.setPenWidth(penWidth);
    // dc.drawRoundedRectangle(x,y, w, l, corner);
    // dc.setColor(fontColor, Graphics.COLOR_TRANSPARENT);
    // dc.drawText(x + w /2 , y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
  }

  hidden function showGrid(dc as Dc) as Void {
    var y = 0;
    var f = 0;
    for (var r = 0; r < mGrid.size(); r++) {
      var row = mGrid[r] as Array<Array<Number> >;
      var x = 0;
      var h = 0;
      for (var c = 0; c < row.size(); c++) {
        //  [w,h]
        var cell = row[c] as Array<Number>;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, cell[0], cell[1]);

        drawField(dc, f, x, y, cell[0], cell[1]);

        x = x + cell[0];
        h = cell[1];
        f = f + 1;
      }
      y = y + h;
    }
  }

  hidden function drawField(
    dc as Dc,
    fieldIdx as Number,
    x as Number,
    y as Number,
    width as Number,
    height as Number
  ) as Void {
    var title = "";
    var value = "";
    var prefix = "";
    var text = "";
    var number = "";
    var decimals = "";
    var units = "";
    var perc = 0;

    if (fieldIdx == 0) {
      title = "grade";
      units = "%";
      var grade = gMetrics.getGrade();
      value = grade.format("%0.1f");
      number = stringLeft(value, ".", value);
      decimals = stringRight(value, ".", "");
      if (grade < 0) {
        grade = grade * -1;
      }
      var iconColor = getIconColor(dc, grade, gTargetGrade);
      checkReverseColor(dc, x, y, width, height);
      drawGradeIcon(dc, x, y, width, height, iconColor);
    } else if (fieldIdx == 1) {
      text = getCompassDirection(gMetrics.getBearing());
    } else if (fieldIdx == 2) {
      var heartRate = gMetrics.getHeartRate();
      if (mPaused or heartRate == 0) {
        title = "time";
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        text = Lang.format("$1$:$2$", [today.hour, today.min.format("%02d")]);
        decimals = today.sec.format("%02d");
        units = Lang.format("$1$ $2$", [today.day, today.month]);
      } else {
        title = "hr";
        units = "bpm";
        number = heartRate.format("%0d");
        var iconColor = getIconColor(dc, heartRate, gTargetHeartRate);
        checkReverseColor(dc, x, y, width, height);
        drawHeartIcon(dc, x, y, width, height, iconColor);
      }
    } else if (fieldIdx == 3) {
      // power 0 or paused -> avg / fallback @@
      title = "power";
      units = "w";
      number = gMetrics.getPower().format("%0d");
      var iconColor = getIconColor(dc, gMetrics.getPower(), gTargetFtp);
      checkReverseColor(dc, x, y, width, height);
      drawPowerIcon(dc, x, y, width, height, iconColor);
    } else if (fieldIdx == 4) {
      title = "speed";
      units = "km/h";
      var speed = mpsToKmPerHour(gMetrics.getSpeed());
      value = speed.format("%0.1f");
      number = stringLeft(value, ".", value);
      decimals = stringRight(value, ".", "");
      var iconColor = getIconColor(dc, speed, gTargetSpeed);
      checkReverseColor(dc, x, y, width, height);
      drawSpeedIcon(dc, x, y, width, height, iconColor);
    } else if (fieldIdx == 5) {
      title = "altitude";
      units = "m";
      if (mpsToKmPerHour(gMetrics.getSpeed()) < 15) {
        value = gMetrics.getAltitude().format("%0.2f");
      } else {
        value = gMetrics.getAltitude().format("%0d");
      }
      number = stringLeft(value, ".", value);
      decimals = stringRight(value, ".", "");
      var iconColor = getIconColor(dc, gMetrics.getAltitude(), gTargetAltitude);
      checkReverseColor(dc, x, y, width, height);
      drawAltitudeIcon(dc, x, y, width, height, iconColor);
    } else if (fieldIdx == 6) {
      title = "cadence";
      units = "rpm";
      number = gMetrics.getCadence().format("%0d");
      drawCadenceIcon(dc, x, y, width, height, getIconColor(dc, gMetrics.getCadence(), gTargetCadence));
    } else if (fieldIdx == 7) {
      if (gHiitt.isEnabled()) {
        title = "hiit";
        var HiitElapsed = gHiitt.getElapsedSeconds();
        var vo2max = gHiitt.getVo2Max();
        text = Lang.format("#$1$ $2$ $3$", [
          gHiitt.getNumberOfHits().format("%0.0d"),
          HiitElapsed.format("%0.0d"),
          vo2max.format("%0.1f"),
        ]);
      } else {
        title = "elapsed";
        var elapsed = millisecondsToShortTimeString(gMetrics.getElapsedTime(), "{h}.{m}:{s}");
        prefix = stringLeft(elapsed, ".", "");
        if (prefix.equals("0")) {
          prefix = "";
        }
        text = stringRight(elapsed, ".", elapsed);
        drawElapsedTimeIcon(dc, x, y, width, height, mIconColor, gMetrics.getElapsedTime());
      }
    }

    // small fields, no decimals and units
    if (height < 30) {
      decimals = "";
      units = "";
    } else {
      if (decimals.equals("0")) {
        decimals = "";
      }
    }

    var dims_prefix = [0, 0] as Array<Number>;
    var dims_number_or_text = [0, 0] as Array<Number>;
    var dims_decimals = [0, 0] as Array<Number>;
    var dims_units = [0, 0] as Array<Number>;

    var fontPrefix = Graphics.FONT_SYSTEM_XTINY;
    if (prefix.length() > 0) {
      dims_prefix = dc.getTextDimensions(prefix, fontPrefix);
    }
    var fontUnits = Graphics.FONT_SYSTEM_XTINY;
    if (units.length() > 0) {
      dims_units = dc.getTextDimensions(units, fontUnits);
    }

    // @@ when alpha working + show in paused and until 1 minute
    // if (title.length()>0) {
    //   dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    //   dc.drawText(x + 1, y, Graphics.FONT_SYSTEM_XTINY, title,
    //   Graphics.TEXT_JUSTIFY_LEFT);
    // }

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

      var fontDecimals = Graphics.FONT_TINY;
      if (decimals.length() > 0) {
        if (font == fontDecimals) {
          fontDecimals = Graphics.FONT_XTINY;
        }
        dims_decimals = dc.getTextDimensions(decimals, fontDecimals);
      }

      var xSplit = (x + (width - dims_number_or_text[0] - dims_decimals[0]) / 2 + dims_number_or_text[0]).toNumber();
      var yBase = y + (height - dims_number_or_text[1]) / 2;
      dc.drawText(xSplit, yBase, font, number_or_text, Graphics.TEXT_JUSTIFY_RIGHT);

      if (decimals.length() > 0) {
        var yDec =
          yBase +
          dims_number_or_text[1] -
          dims_decimals[1] -
          Graphics.getFontDescent(font) +
          Graphics.getFontDescent(fontDecimals);
        dc.setColor(mDecimalsColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xSplit, yDec, fontDecimals, decimals, Graphics.TEXT_JUSTIFY_LEFT);
      }

      if (units.length() > 0) {
        var yUnits =
          yBase +
          dims_number_or_text[1] -
          dims_units[1] -
          Graphics.getFontDescent(font) +
          Graphics.getFontDescent(fontUnits);
        dc.setColor(mUnitsColor, Graphics.COLOR_TRANSPARENT);

        var xUnits = xSplit + dims_decimals[0] + 1;
        if (xUnits + dims_units[0] > width) {
          // Units on center bottom when small field
          xUnits = x + width / 2 - dims_units[0] / 2;
          yUnits = yBase + dims_number_or_text[1] - Graphics.getFontDescent(font) - Graphics.getFontDescent(fontUnits);
        }
        dc.drawText(xUnits, yUnits, fontUnits, units, Graphics.TEXT_JUSTIFY_LEFT);
      }
      if (prefix.length() > 0) {
        var xPrefix = xSplit - dims_number_or_text[0] - dims_prefix[0];
        var yPrefix = y + height / 2 - dims_number_or_text[1] / 2; // - dims_prefix[1] / 2;

        dc.drawText(xPrefix, yPrefix, fontPrefix, prefix, Graphics.TEXT_JUSTIFY_LEFT);
      }
    }
  }

  hidden function getIconColor(dc as Dc, value as Numeric, maxValue as Numeric) as Graphics.ColorType {
    mReverseColor = false;
    if (gShowColors) {
      var perc = percentageOf(value, maxValue);
      mReverseColor = perc >= 165;
      return percentageToColor(perc, 255, $.PERC_COLORS_SCHEME);
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
    color as ColorType
  ) as Void {
    var r = (height / 4).toNumber();
    var x0 = (x + width / 2).toNumber();
    var y1 = (y + 1.5 * r).toNumber();
    var x1 = (x0 - 0.9 * r).toNumber();
    var x2 = (x1 + 1.8 * r).toNumber();

    var xc1 = pointOnCircle_x(x1, y1, r, 135);
    var yc1 = pointOnCircle_y(x1, y1, r, 135);
    var xc2 = pointOnCircle_x(x2, y1, r, 45);
    var yc2 = pointOnCircle_y(x2, y1, r, 45);
    var y3 = y + height - 0.5 * r;

    setColorFillStroke(dc, color);
    dc.fillCircle(x1, y1, r);
    dc.fillCircle(x2, y1, r);
    dc.fillPolygon(
      [
        [xc1, yc1],
        [x0, y3],
        [xc2, yc2],
        [x0, y1],
      ] as Array<Array<Number> >
    );
  }
  hidden function drawGradeIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var m = height / 6;
    var x1 = x + m;
    var y1 = y + height - m;
    var x2 = x + width - m;
    var y2 = y1;
    var x3 = x2;
    var y3 = y + m;

    setColorFillStroke(dc, color);
    dc.fillPolygon(
      [
        [x1, y1],
        [x2, y2],
        [x3, y3],
      ] as Array<Array<Number> >
    );
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
    var mx = height / 8;
    // If paused @@ then ||
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
      ] as Array<Array<Number> >
    );
  }
  hidden function drawPowerIcon(
    dc as Dc,
    x as Number,
    y as Number,
    width as Number,
    height as Number,
    color as ColorType
  ) as Void {
    var my = height / 5;
    var mx = width / 6;

    var x1 = x + width / 2 + mx;
    var y1 = y + my;

    var x2 = x + width / 2 - 1.2 * mx;
    var y2 = y + height / 2 + 2;

    var x3 = x2 + mx;
    var y3 = y2;

    var x4 = x + width / 2 - mx;
    var y4 = y + height - my;

    var x5 = x + width / 2 + 1.2 * mx;
    var y5 = y + height / 2 - 2;

    var x6 = x + width / 2;
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
      ] as Array<Array<Number> >
    );
  }

  /*
@@ draw dark colors -> font whit + background gray
  dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.fillRectangle(x, y, width, height);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
  */
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
    var m = height / 5;
    var d = width / 6;
    var x1 = x + d;
    var y1 = y + height - m;
    var x2 = x1 + 1.5 * d;
    var y2 = y + m;
    var x3 = x2 + 0.5 * d;
    var y3 = y + 3 * m; // + height / 4;
    var x4 = x3 + d;
    var y4 = y + 2 * m; // + height / 2;
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
      ] as Array<Array<Number> >
    );
  }

  hidden function showDebugValues(dc as Dc) as Void {
    var font = Graphics.FONT_MEDIUM;
    var x = 1;
    var y = 1;
    var l = dc.getFontHeight(font);
    // dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    // var x = dc.getWidth() / 2;
    // var y = dc.getHeight() / 2;
    // dc.drawText(
    //   x,
    //   y,
    //   Graphics.FONT_LARGE,
    //   mFieldSize,
    //   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    // );
    // var cadence = gMetrics.getCadence();
    // var maxCadence = gMetrics.getMaxCadence();
    // var perc = percentageOf(cadence, maxCadence);

    // // drawPercentageCircleTarget(dc, x, y + 50, 50, perc, 50);

    // dc.drawText(
    //   x,
    //   y,
    //   font,
    //   Lang.format("RPM: $1$/$2$", [cadence, maxCadence]),
    //   Graphics.TEXT_JUSTIFY_LEFT
    // );

    y = y + l;
    dc.drawText(x, y, font, Lang.format("Alt: $1$", [gMetrics.getAltitude()]), Graphics.TEXT_JUSTIFY_LEFT);
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format("Grade: $1$", [gMetrics.getGrade().format("%0.1f")]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    y = y + l;
    var grades = "";
    for (var i = 0; i < gMetrics.getGradeArray().size(); i++) {
      grades = grades + gMetrics.getGradeArray()[i].format("%0.2f") + " ";
    }
    dc.drawText(x, y, Graphics.FONT_SMALL, Lang.format("Grade: $1$", [grades]), Graphics.TEXT_JUSTIFY_LEFT);
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format("Bearing: $1$", [getCompassDirection(gMetrics.getBearing())]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format("Power: $1$", [gMetrics.getPower().format("%0.0d")]),
      Graphics.TEXT_JUSTIFY_LEFT
    );

    var HiitElapsed = gHiitt.getElapsedSeconds();
    var vo2max = gHiitt.getVo2Max();
    y = y + l;
    dc.drawText(
      x,
      y,
      font,
      Lang.format("Hiit: #$1$ $2$ $3$", [
        gHiitt.getNumberOfHits().format("%0.0d"),
        HiitElapsed.format("%0.0d"),
        vo2max.format("%0.1f"),
      ]),
      Graphics.TEXT_JUSTIFY_LEFT
    );
  }
}
