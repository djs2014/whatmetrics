import Toybox.System;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Activity;
import Toybox.Time;
import Toybox.Time.Gregorian;

const MILE = 1.609344;
const FEET = 3.281;

var gCreateColors as Boolean = false;
var gUseSetFillStroke as Boolean = false;

function getActivityValue(info as Activity.Info?, symbol as Symbol, dflt as Lang.Object) as Lang.Object {
  if (info == null) {
    return dflt;
  }
  var ainfo = info as Activity.Info;

  if (ainfo has symbol) {
    if (ainfo[symbol] != null) {
      return ainfo[symbol] as Lang.Object;
    }
  }
  return dflt;
}

function getStorageValue(
  key as Application.PropertyKeyType,
  dflt as Application.PropertyValueType
) as Application.PropertyValueType {
  try {
    var val = Toybox.Application.Storage.getValue(key);
    if (val != null) {
      return val;
    }
  } catch (ex) {
    return dflt;
  }
  return dflt;
}

function percentageOf(value as Numeric?, max as Numeric?) as Numeric {
  if (value == null || max == null) {
    return 0.0f;
  }
  if (max <= 0) {
    return 0.0f;
  }
  return value / (max / 100.0);
}

function drawPercentageLine(
  dc as Dc,
  x as Number,
  y as Number,
  maxwidth as Number,
  percentage as Numeric,
  height as Number,
  color as ColorType
) as Void {
  var wPercentage = (maxwidth / 100.0) * percentage;
  dc.setColor(color, Graphics.COLOR_TRANSPARENT);

  dc.fillRectangle(x, y, wPercentage, height);
  dc.drawPoint(x + maxwidth, y);
}

function drawPercentageCircleTarget(
  dc as Dc,
  x as Number,
  y as Number,
  radius as Number,
  perc as Numeric,
  circleWidth as Number,
  alpha as Number
) as Void {
  dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
  dc.drawCircle(x, y, radius);

  setColorByPerc(dc, perc, alpha);
  drawPercentageCircle(dc, x, y, radius, perc, circleWidth);

  var percRemain = perc - 100;
  var radiusInner = radius - circleWidth - 3;
  while (percRemain > 0 && radiusInner > 0) {
    setColorByPerc(dc, percRemain, alpha);
    drawPercentageCircle(dc, x, y, radiusInner, percRemain, circleWidth);

    radiusInner = radiusInner - circleWidth - 3;
    percRemain = percRemain - 100;
  }
}

function drawPercentageCircle(
  dc as Dc,
  x as Number,
  y as Number,
  radius as Number,
  perc as Numeric,
  penWidth as Number
) as Void {
  if (perc == null || perc == 0) {
    return;
  }

  if (perc > 100) {
    perc = 100;
  }
  var degrees = 3.6 * perc;

  var degreeStart = 180; // 180deg == 9 o-clock
  var degreeEnd = degreeStart - degrees; // 90deg == 12 o-clock

  dc.setPenWidth(penWidth);
  dc.drawArc(x, y, radius, Graphics.ARC_CLOCKWISE, degreeStart, degreeEnd);
  dc.setPenWidth(1.0);
}

function meterToFeet(meter as Numeric?) as Float {
  if (meter == null) {
    return 0.0f;
  }
  return (meter * FEET) as Float;
}

function kilometerToMile(km as Numeric?) as Float {
  if (km == null) {
    return 0.0f;
  }
  return (km / MILE) as Float;
}

function mpsToKmPerHour(metersPerSecond as Numeric?) as Float {
  if (metersPerSecond == null) {
    return 0.0f;
  }
  return ((metersPerSecond * 60 * 60) / 1000.0) as Float;
}

function getDistanceInMeterOrKm(distanceInMeters as Float) as Float {
  if (distanceInMeters > 1000) {
    return distanceInMeters / 1000.0f;
  } else {
    return distanceInMeters;
  }
}
function getUnitsInMeterOrKm(distanceInMeters as Float) as String {
  if (distanceInMeters > 1000) {
    return "km";
  } else {
    return "m";
  }
}
function getFormatForMeterAndKm(distanceInMeters as Float) as String {
  if (distanceInMeters > 1000) {
    return "%0.2f";
  } else {
    return "%0d";
  }
}

function deg2rad(deg as Numeric) as Double or Float {
  return deg * (Math.PI / 180);
}

function rad2deg(rad as Numeric) as Double or Float {
  var deg = (rad * 180) / Math.PI;
  if (deg < 0) {
    deg += 360.0;
  }
  return deg as Double or Float;
}

// bearing in degrees
function getCompassDirection(bearing as Numeric) as String {
  var direction = "";
  // Round and convert to number (1.00000 -> 1)
  switch (Math.round(bearing / 22.5).toNumber()) {
    case 1:
      direction = "NNE";
      break;
    case 2:
      direction = "NE";
      break;
    case 3:
      direction = "ENE";
      break;
    case 4:
      direction = "E";
      break;
    case 5:
      direction = "ESE";
      break;
    case 6:
      direction = "SE";
      break;
    case 7:
      direction = "SSE";
      break;
    case 8:
      direction = "S";
      break;
    case 9:
      direction = "SSW";
      break;
    case 10:
      direction = "SW";
      break;
    case 11:
      direction = "WSW";
      break;
    case 12:
      direction = "W";
      break;
    case 13:
      direction = "WNW";
      break;
    case 14:
      direction = "NW";
      break;
    case 15:
      direction = "NNW";
      break;
    default:
      direction = "N";
  }

  return direction;
}

// pascal -> mbar (hPa)
function pascalToMilliBar(pascal as Numeric?) as Float {
  if (pascal == null) {
    return 0.0f;
  }
  return (pascal / 100.0) as Float;
}

function getMatchingFont(
  dc as Dc,
  fontList as Array,
  maxWidth as Number,
  maxHeight as Number,
  text as String
) as FontType {
  var index = fontList.size() - 1;
  var font = fontList[index] as FontType;
  // System.println(Lang.format("text[$1$] max w[$2$]h[$3$]",[text, maxWidth, maxHeight]));
  // wxh
  var dimensions = dc.getTextDimensions(text, font);
  // System.println(Lang.format(" dim w[$1$]h[$2$]",dimensions));
  // while height or width of font too big, find another font
  while ((dimensions[0] > maxWidth || dimensions[1] > maxHeight) && index > 0) {
    index = index - 1;
    font = fontList[index] as FontType;
    dimensions = dc.getTextDimensions(text, font);
    // System.println(Lang.format(" dim w[$1$]h[$2$]",dimensions));
  }
  // System.println("font index: " + index);
  return font;
}

function checkFeatures() as Void {
  $.gCreateColors = Graphics has :createColor;
  try {
    $.gUseSetFillStroke = Graphics.Dc has :setStroke;
    if ($.gUseSetFillStroke) {
      $.gUseSetFillStroke = Graphics.Dc has :setFill;
    }
  } catch (ex) {
    ex.printStackTrace();
  }
}

function setColorByPerc(dc as Dc, perc as Numeric, alpha as Number) as Void {
  var color = percentageToColor(perc, alpha, $.PERC_COLORS_SCHEME, 0);
  if ($.gUseSetFillStroke) {
    dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_TRANSPARENT);
    dc.setFill(color);
    dc.setStroke(color);
  } else {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
  }
}

function setColorFillStroke(dc as Dc, color as Graphics.ColorType) as Void {
  if ($.gUseSetFillStroke) {
    dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_TRANSPARENT);
    dc.setFill(color);
    dc.setStroke(color);
  } else {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
  }
}

// [perc, R, G, B]
const PERC_COLORS_RED =
  [
    [0, 255, 255, 255],
    [50, 155, 100, 100],
    [100, 255, 0, 0],
  ] as Array<Array<Number> >;

const PERC_COLORS_SCHEME =
  [
    [0, 244, 244, 244],
    [55, 233, 233, 247], // COLOR_WHITE_4
    [65, 174, 214, 241], // COLOR_WHITE_BLUE_3
    [70, 169, 204, 227], // COLOR_WHITE_DK_BLUE_3
    [75, 163, 228, 215], // COLOR_WHITE_LT_GREEN_3
    [80, 169, 223, 191], // COLOR_WHITE_GREEN_3
    [85, 249, 231, 159], // COLOR_WHITE_YELLOW_3
    [95, 250, 215, 160], // COLOR_WHITE_ORANGE_3
    [100, 250, 229, 211], // COLOR_WHITE_ORANGERED_2
    [105, 245, 203, 167], // COLOR_WHITE_ORANGERED_3
    [115, 237, 187, 153], // COLOR_WHITE_ORANGERED2_3
    [125, 245, 183, 177], // COLOR_WHITE_RED_3
    [135, 230, 176, 170], // COLOR_WHITE_DK_RED_3
    [145, 215, 189, 226], // COLOR_WHITE_PURPLE_3
    [155, 210, 180, 222], // COLOR_WHITE_DK_PURPLE_3
    [165, 187, 143, 206], // COLOR_WHITE_DK_PURPLE_4
    [999, 0, 0, 0], // COLOR_WHITE_DK_PURPLE_4
  ] as Array<Array<Number> >;

// alpha, 255 is solid, 0 is transparent
function percentageToColor(
  percentage as Numeric?,
  alpha as Number,
  colorScheme as Array<Array<Number> >,
  darker as Number
) as ColorType {
  var pcolor = 0;
  var pColors = colorScheme;
  if (percentage == null) {
    return Graphics.createColor(alpha, 255, 255, 255);
  }

  var i = 1;
  while (i < pColors.size()) {
    pcolor = pColors[i] as Array<Number>;
    if (percentage <= pcolor[0]) {
      break;
    }
    i++;
  }
  if (i >= pColors.size()) {
    i = pColors.size() - 1;
  }

  var lower = pColors[i - 1];
  var upper = pColors[i];
  var range = upper[0] - lower[0];
  var rangePct = 1;
  if (range != 0) {
    rangePct = (percentage - lower[0]) / range;
  }
  var pctLower = 1 - rangePct;
  var pctUpper = rangePct;

  var red = Math.floor(lower[1] * pctLower + upper[1] * pctUpper);
  var green = Math.floor(lower[2] * pctLower + upper[2] * pctUpper);
  var blue = Math.floor(lower[3] * pctLower + upper[3] * pctUpper);

  if (darker > 0 && darker < 100) {
    red = red - (red / 100) * darker;
    green = green - (green / 100) * darker;
    blue = blue - (blue / 100) * darker;
  }
  return Graphics.createColor(alpha, red.toNumber(), green.toNumber(), blue.toNumber());
}

// template: "{h}:{m}:{s}:{ms}"
function millisecondsToShortTimeString(totalMilliSeconds as Number, template as String) as String {
  if (totalMilliSeconds != null && totalMilliSeconds instanceof Lang.Number) {
    var hours = (totalMilliSeconds / (1000.0 * 60 * 60)).toNumber() % 24;
    var minutes = (totalMilliSeconds / (1000.0 * 60.0)).toNumber() % 60;
    var seconds = (totalMilliSeconds / 1000.0).toNumber() % 60;
    var mseconds = totalMilliSeconds.toNumber() % 1000;

    if (template.length() == 0) {
      template = "{h}:{m}:{s}:{ms}";
    }
    var time = stringReplace(template, "{h}", hours.format("%01d"));
    time = stringReplace(time, "{m}", minutes.format("%02d"));
    time = stringReplace(time, "{s}", seconds.format("%02d"));
    time = stringReplace(time, "{ms}", mseconds.format("%03d"));

    return time;
  }
  return "";
}

// 1:40 or 150:40
function secondsToCompactTimeString(totalSeconds as Number, template as String) as String {
  if (totalSeconds != null && totalSeconds instanceof Lang.Number) {
    var minutes = (totalSeconds / 60.0).toNumber();
    var seconds = totalSeconds.toNumber() % 60;

    var time = stringReplace(template, "{m}", minutes.format("%01d"));
    time = stringReplace(time, "{s}", seconds.format("%02d"));

    return time;
  }
  return "";
}

// 1:40 or 150:40 (if no {h} in template)
function secondsToHourMinutes(totalSeconds as Number) as String {
  if (totalSeconds != null && totalSeconds instanceof Lang.Number) {
    var timeString = "{h}:{m}";
    var hours = (totalSeconds / (60 * 60)).toNumber(); // % 24;
    timeString = $.stringReplace(timeString, "{h}", hours.format("%01d"));
    var minutes = (totalSeconds / 60.0).toNumber() % 60;
    timeString = $.stringReplace(timeString, "{m}", minutes.format("%01d"));

    return timeString;
  }
  return "";
}

function stringReplace(str as String, oldString as String, newString as String) as String {
  //str = str.toString(); // @@ TODO why crash here? -> because of too many nested function calls?
  if (str.length() == 0 || oldString.length() == 0) {
    return str;
  }

  var result = str;
  var index = result.find(oldString);
  var count = 0;
  while (index != null && count < 30) {
    var indexEnd = index + oldString.length();
    var res = result.substring(0, index) + newString + result.substring(indexEnd, result.length());
    result = res;
    index = result.find(oldString);
    count = count + 1;
  }

  return result;
}

function stringLeft(str as String, marker as String, dflt as String) as String {
  if (str.length() == 0 || marker.length() == 0) {
    return dflt;
  }

  var index = str.find(marker);
  if (index == null) {
    return dflt;
  }
  return str.substring(0, index) as String;
}

function stringRight(str as String, marker as String, dflt as String) as String {
  if (str.length() == 0 || marker.length() == 0) {
    return dflt;
  }

  var index = str.find(marker);
  if (index == null || index + 1 >= str.length()) {
    return dflt;
  }
  return str.substring(index + 1, null) as String;
}

function pointOnCircle_x(x as Number, y as Number, radius as Number, angleInDegrees as Number) as Number {
  // Convert from degrees to radians
  return (radius * Math.cos(deg2rad(angleInDegrees)) + x).toNumber();
}
function pointOnCircle_y(x as Number, y as Number, radius as Number, angleInDegrees as Number) as Number {
  // Convert from degrees to radians
  return (radius * Math.sin(deg2rad(angleInDegrees)) + y).toNumber();
}
