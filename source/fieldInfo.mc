import Toybox.Lang;
import Toybox.System;

class FieldInfo {
    var type as FieldType = FTDistance;
    var index as Number = 0;

    var available as Boolean = true;
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

    var iconColor as Number = -1;
    var iconParam as Numeric = 0;
    var iconParam2 as Numeric = 0;

    function initialize(fieldType as FieldType, fieldIndex as Number) {
        type = fieldType;
        index = fieldIndex;
    }
}

const FieldLayoutCount = 3;
enum FieldLayout {
    FL8Fields = 0,
    FL6Fields = 1,
    FL4Fields = 2
}

const FieldTypeCount = 26; // incl the 0
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
    FTTimeElapsed = 16,
    FTGearCombo = 17,
    FTPowerPerWeight = 18,
    FTPowerBalance = 19,    
    FTHeartRateZone = 20,
    FTGearIndex = 21,
    FTAverageSpeed = 22,
    FTAverageHeartRate = 23,    
    FTAveragePower = 24,
    FTAverageCadence = 25,

    // @@ TODO
    // FTVo2Max = 22,
    // FTCalories = 23,
    // FTEnergyExpenditure = 24,
    // FTTrainingEffect = 25,
    // FTTotalAscent = 26,
    // FTTotalDescent = 27,
    // FTAverage ..
  }

enum ZenMode {
    ZMOff = 0,
    ZMOn = 2,
    ZMWhenMoving = 3 // on when moving
}