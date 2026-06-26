import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

public class HeartRate {
    var mHeartRateZones as Array<Number> = [] as Array<Number>;
    var mWarmUpHeartRate as Number = 60; // bpm

    function initialize() {
        //mIsInWarmUp = false;
    }

    function initHrZones() as Void {
        // Array of heart rate zones for biking, in beats per minute (BPM)
        // [minzone1, maxzone1, maxzone2, maxzone3, maxzone4, maxzone5]
        mHeartRateZones = UserProfile.getHeartRateZones(
            UserProfile.HR_ZONE_SPORT_BIKING
        );
        if (mHeartRateZones == null || mHeartRateZones.size() < 6) {
            // Fallback safety values if the user profile is uninitialized
            mHeartRateZones = [100, 125, 145, 160, 175, 190];
            $.logInfo([
                "Heart rate zones not initialized, using fallback:",
                mHeartRateZones,
            ]);
        } else {
            $.logInfo(["Heart rate zones initialized:", mHeartRateZones]);
        }
    }

    function getHeartRateZone(heartRate as Number) as Number {
        if (mHeartRateZones.size() == 0) {
            return 0;
        }

        if (heartRate < mHeartRateZones[0]) {
            return 0;
        }

        for (var i = 1; i < mHeartRateZones.size(); i++) {
            if (heartRate < mHeartRateZones[i]) {
                return i;
            }
        }

        return mHeartRateZones.size();
    }

    // Returns a float between 0.0 and 1.0 representing the progress through the target zone
    function calculateZoneProgress(
        liveHeartRate as Number,
        targetZone as Float
    ) as Float {
        if (mHeartRateZones.size() < 6 || targetZone < 1 || targetZone > 5) {
            return 0.0f;
        }

        // 1. Get the floor and ceiling bounds for this exact targeted zone
        // 6:48:40 - [Heart rate zones initialized:, [128, 153, 179, 204, 230, 255]]

        // 3. Convert our target decimal zone (e.g., 2.2f) into an exact target BPM
        var targetZoneInt = targetZone.toNumber(); // e.g., 2
        var zoneFloor = mHeartRateZones[targetZoneInt - 1]; // e.g., if targetZone=2, floor is index 1 (153)
        var zoneCeiling = mHeartRateZones[targetZoneInt]; // e.g., if targetZone=2, ceiling is index 2 (179)
        var zoneRemainder = targetZone - targetZoneInt; // e.g., 0.2f

        // Calculate the exact target BPM for this decimal zone (e.g., 2.2f)
        var targetBpm = zoneFloor + zoneRemainder * (zoneCeiling - zoneFloor);
        // Calculate progress relative to the target BPM
        // If the athlete is at the target BPM exactly, ratio is 1.0f
        var progressRatio = liveHeartRate.toFloat() / targetBpm;

        System.println(
            "HeartRate: liveHR=" +
                liveHeartRate +
                " targetZone=" +
                targetZone +
                " targetBpm=" +
                targetBpm +
                " progressRatio=" +
                calculateCurrentDecimalZone(liveHeartRate) 
        );
        return progressRatio; // e.g., if HR is 166 and targetBpm is 166, returns 1.0f (Perfectly on target!)
    }

    function getBpmFromDecimalZone(decimalZone as Float) as Number {
        if (mHeartRateZones.size() < 6) {
            return 0;
        }

        // Safety clamp to keep things within bounds
        if (decimalZone < 1.0f) {
            decimalZone = 1.0f;
        }
        if (decimalZone > 5.0f) {
            decimalZone = 5.0f;
        }

        // 1. Get the base zone index (e.g., 1.8f becomes 1)
        var baseZoneId = decimalZone.toNumber();

        // 2. Find the low and high boundaries for this specific zone
        var zoneFloor = mHeartRateZones[baseZoneId - 1]; // e.g., index 0 for Z1
        var zoneCeiling = mHeartRateZones[baseZoneId]; // e.g., index 1 for Z1 ceiling

        // 3. Extract the decimal remainder (e.g., 1.8f -> 0.8f)
        var remainder = decimalZone - baseZoneId;

        // 4. Interpolate the exact target heart rate between those two boundaries
        var targetBpm = zoneFloor + remainder * (zoneCeiling - zoneFloor);

        return targetBpm.toNumber(); // Round to the nearest whole heartbeat
    }

    function calculateCurrentDecimalZone(liveHeartRate as Number) as Float {
        if (mHeartRateZones.size() < 6 || liveHeartRate <= 0) {
            return 1.0f; // Default to Zone 1 if zones are uninitialized
        }
        
    
        // 2. Handle the absolute basement (Below Zone 1 floor)
        if (liveHeartRate < mHeartRateZones[0]) {
            return 1.0f;
        }

        // 3. Loop through boundaries to see where the live HR lands
        for (var i = 1; i < 6; i++) {
            var zoneFloor = mHeartRateZones[i - 1];
            var zoneCeiling = mHeartRateZones[i];

            if (liveHeartRate >= zoneFloor && liveHeartRate <= zoneCeiling) {
                // Find the percentage of progress inside this single zone bracket
                var chunkRange = (zoneCeiling - zoneFloor).toFloat();
                var positionInChunk = (liveHeartRate - zoneFloor).toFloat();
                if (chunkRange <= 0.0f) {
                    return i.toFloat(); // Avoid division by zero
                }
                var fractionalZone = positionInChunk / chunkRange;

                // Return the base zone index + the fractional progress
                // (e.g., Index 1 means we are inside Zone 2, so 2.0f + fractionalZone)
                return i.toFloat() + fractionalZone;
            }
        }

        // 4. Handle the roof (Exceeding Zone 5 maximum)
        return 5.9f;
    }

    function getMaxHeartRateZone() as Float {
        if (mHeartRateZones.size() == 0) {
            return 0.0f;
        }
        return (mHeartRateZones.size() - 1).toFloat(); // Max zone is the last index (5.0f for Zone 5)
    }
}
