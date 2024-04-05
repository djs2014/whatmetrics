import Toybox.Lang;
import Toybox.System;

class FieldInfo {
    var index as Number = 0;
    var type as FieldType = FTDistance;
    var title as String = "";
    var value as String = "";
    var number as String = "";
    var prefix as String = "";
    var text as String = "";
    var decimals as String = "";
    var units as String = "";
    var units_side as String = "";
    var text_botleft as String = "";
    var text_botright as String = "";
    var text_middleleft as String = "";
    var text_middleright as String = "";

    var iconColor as Number = 0;
    var iconValue as Numeric = 0;
}

enum FieldType {
    FTUnknown = 0,
    FTDistance = 1,
    FTDistanceNext = 2,
    FTDistanceDest = 3,
    FTGrade = 4,
    FTClock = 5,
    FTHeartRate = 6,
    FTPower = 7,
    FTBearing = 8,
    FTSpeed = 9,
    FTAltitude = 10,
    FTPressureAtSea = 11,
    FTPressure = 12,
    FTCadence = 13,
    FTHiit = 14,
    FTTimer = 15,
    FTTimeElapsed = 16
  }