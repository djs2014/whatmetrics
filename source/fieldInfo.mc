import Toybox.Lang;
import Toybox.System;

class FieldInfo {
    var type as FieldType = FTDistance;
    // 1-based index. !!
    var index as Number = 0;

    var available as Boolean = true;
    // var targetAvailable as Boolean = true;
    var title as String = "";
    var tag as String = "";
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
    // var text_middletop as String = "";

    var iconColor as Number = -1;
    var iconParam as Numeric = 0;
    var iconParam2 as Numeric = 0;

    var rawValue as Numeric = 0;
    var maxValue as Numeric = 0;
    var minValue as Numeric = 0;
    var barReversed as Boolean = false;
    
    function initialize(fieldType as FieldType, fieldIndex as Number) {
        type = fieldType;
        index = fieldIndex;
    }
    function reset() as Void {
        type = FTUnknown;
        index = 0;
        available = true;
        title = "";
        tag = "";
        value = "";
        number = "";
        prefix = "";
        text = "";
        decimals = "";
        units = "";
        units_side = "";
        text_botleft = "";
        text_botright = "";
        text_middleleft = "";
        text_middleright = "";
        // text_middletop = "";

        iconColor = -1;
        iconParam = 0;
        iconParam2 = 0;

        rawValue = 0;
        maxValue = 0;
        minValue = 0;
        barReversed = false;
    }
}

const FieldLayoutCount = 5;
enum FieldLayout {
    FL8Fields = 0,
    FL6Fields = 1,
    FL4Fields = 2,
    FL6SSFields = 3,
    FL8SSFields = 4
}

// Note. will be overridden for devices low on memory (1030)
var FieldTypeCount = 40; // incl the 0
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
    FTPowerBalance = 19,    // @@ TODO
    FTHeartRateZone = 20,
    FTGearIndex = 21,
    FTAverageSpeed = 22,
    FTAverageHeartRate = 23,    
    FTAveragePower = 24,
    FTAverageCadence = 25,
    FTNormalizedPower = 26,
    FTIntensityFactor = 27,
    FTTrainingStressScore = 28,
    FTCalories = 29,
    FTEta = 30, // Estimated Time of Arrival hh:mm
    FTEtr = 31, // Estimated Time Remaining   x hour, x min
    FTVo2MaxHiit = 32, // Hiit Vo2max default
    FTVo2MaxProfile = 33, // Profile Vo2max default
    FTTime2SunUp = 34,
    FTTime2SunDown = 35,
    FTTime2SunUpDown = 36, // Only sun up/down for today!
    FTTime2SunUpDownLoop = 37, 
    FTPerc2SunUpDown = 38, 
    FTPerc2SunUpDownLoop = 39, 
    // @@ TODO
    // FTEnergyExpenditure = 24,
    // FTTrainingEffect = 25,
    // FTTotalAscent = 26,
    // FTTotalDescent = 27,    
  }

enum ZenMode {
    ZMOff = 0,
    ZMOn = 1,
    ZMWhenMoving = 2 // on when moving
}

enum BarPosition {
    BPOff = 0,
    BPTop = 1,
    BPBottom = 2
}

enum Vo2MaxBackGround {
    Vo2BgOff = 0,
    Vo2BgOn = 1, // continuous
    Vo2BgHiit = 2, // during Hiit 
    Vo2BgHiitOnly = 3 // only Hiit scores
}

// field need targetvalue, % to target
enum FocusField {
    FocusOff = 0,
    FocusOn = 1, 
    FocusColor = 2
}
