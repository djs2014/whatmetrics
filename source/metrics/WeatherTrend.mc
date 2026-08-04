import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;

class WeatherTrend {
    // 3 hours divided into 15-minute chunks = 12 data points
    private const HISTORICAL_POINTS = 12; 
    private var pressureHistory as Array<Float> = new [HISTORICAL_POINTS] as Array<Float>;
    
    private var lastSampleTime = 0;
    // 15 minutes = 900,000 milliseconds
    private var sampleIntervalMs = 15 * 60 * 1000; 

    function initialize() {
        // Initialize the array with null or 0.0f
        for (var i = 0; i < HISTORICAL_POINTS; i++) {
            pressureHistory[i] = 0.0f;
        }
    }

    function compute(info as Activity.Info) as Void {
        var currentTime = System.getTimer();

        // Sample the MSLP exactly once every 15 minutes
        if (lastSampleTime == 0 || (currentTime - lastSampleTime) >= sampleIntervalMs) {
            lastSampleTime = currentTime;

            if (info has :meanSeaLevelPressure && info.meanSeaLevelPressure != null) {
                // Shift all older elements to the left to make room for the newest pressure point
                for (var i = 0; i < HISTORICAL_POINTS - 1; i++) {
                    pressureHistory[i] = pressureHistory[i + 1];
                }
                // Append the newest Mean Sea Level Pressure (converted to hPa/millibars)
                // Garmin native MSLP is usually returned in Pascals (Pa), so divide by 100 for hPa
                pressureHistory[HISTORICAL_POINTS - 1] = info.meanSeaLevelPressure / 100.0f;
            }
        }

        if (pressureHistory[0] != 0.0f) {
            var newestPressure = pressureHistory[HISTORICAL_POINTS - 1];
            var oldestPressure = pressureHistory[0];
            var elapsedPoints = 0;

            // Scan the array from left to right to find the oldest valid point
            for (var i = 0; i < HISTORICAL_POINTS; i++) {
                if (pressureHistory[i] != 0.0f) {
                    oldestPressure = pressureHistory[i];
                    // How many 15-minute intervals do we actually have?
                    elapsedPoints = (HISTORICAL_POINTS - 1) - i; 
                    break; // Found it, stop scanning
                }
            }

            if (oldestPressure != 0.0f && elapsedPoints > 0) {                
                // 1. Calculate current hourly rate of change (Velocity)
                var intervalsPerHour = 4.0f; 
                var hoursElapsed = elapsedPoints.toFloat() / intervalsPerHour;
                var currentRatePerHour = (newestPressure - oldestPressure) / hoursElapsed;

                // 2. PREDICTED DELTA (Where will we be in 1 hour if this momentum keeps up?)
                // If we've only been riding 30 mins, this projects the trend line out to the 1-hour mark.
                var predictedDropNextHour = currentRatePerHour * 1.0f; 

                // 3. MAP TO TREND VALUE (0.0 to 1.0) 
                // We combine current state with the prediction to make the bubble reactive.
                // If the pressure is dropping AND accelerating downward, make the bubble surge upward.
                if (currentRatePerHour <= -1.0f || predictedDropNextHour <= -1.2f) {
                    // Impending Storm Warning -> Sudden high-velocity drop predicted
                    mPressureTrend = 1.0f; 
                } else if (currentRatePerHour < 0.0f) {
                    // Use the more severe of the two (current vs predicted) to err on the side of safety
                    var severity = currentRatePerHour.abs() > predictedDropNextHour.abs() ? currentRatePerHour.abs() : predictedDropNextHour.abs();
                    mPressureTrend = severity * 0.7f;
                } else {
                    // Pressure rising or stable
                    mPressureTrend = 0.0f;
                }

                // OPTIONAL: Store the raw predicted delta value to print inside the bubble text!
                // e.g., "Exp: -1.4" so the user sees the predicted hPa drop.
                mPredictedWeatherDelta = predictedDropNextHour; 
            }
            
            // Only calculate if we have a valid baseline and at least 15 minutes of data
            // if (oldestPressure != 0.0f && elapsedPoints > 0) {
            //     var rawDelta = newestPressure - oldestPressure;

            //     // If the ride is only 45 minutes long (3 intervals), a 1 hPa drop 
            //     // is just as dangerous as a 4 hPa drop over 3 hours!
            //     // We normalize the delta to a standard "Change per Hour" rate.
            //     var intervalsPerHour = 4.0f; // 60 mins / 15 min intervals
            //     var hoursElapsed = elapsedPoints.toFloat() / intervalsPerHour;

            //     // This gives you the drop rate projected over an hour
            //     var pressureChangePerHour = rawDelta / hoursElapsed;

            //     // Meteorological rule of thumb: A drop of > 1.0 hPa per hour 
            //     // means a severe flash storm or squall front is hitting.
            //     if (pressureChangePerHour <= -1.0f) {
            //         // Critical Drop Rate -> Send bubble to the absolute top
            //         mProgressRatios[WEATHER_BUBBLE_INDEX] = 1.0f; 
            //     } else if (pressureChangePerHour < 0.0f) {
            //         // Proportional scale for mild tracking drops
            //         mProgressRatios[WEATHER_BUBBLE_INDEX] = pressureChangePerHour.abs() * 0.8f;
            //     } else {
            //         mProgressRatios[WEATHER_BUBBLE_INDEX] = 0.0f;
            //     }
            // }
            // mPressureDelta = newestPressure - oldestPressure;
            
            // Check if we have at least two valid data points to compare


            // if (mPressureDelta <= -3.0f) {
            //     // Severe Drop 
            //     mPressureTrend = 1.0f; 
            // } else if (mPressureDelta < 0.0f) {
            //     // Mild Drop 
            //     mPressureTrend = (mPressureDelta.abs() / 3.0f) * 0.8f;
            // } else {
            //     // Pressure is steady or rising 
            //     mPressureTrend = 0.0f;
            // }
        }
    }

    var mPredictedWeatherDelta as Float = 0.0f;

    var mPressureTrend as Float = 0.0f;
    // var mPressureDelta as Float = 0.0f;

    function getPressureTrend() as Float {
        return mPressureTrend;
    }
    function getPredictedWeatherDelta() as Float {
        return mPredictedWeatherDelta;
    }
}

// var alertText = "";
//         if (mPredictedWeatherDelta <= -1.0f) {
//             alertText = "STORM"; // Predicted crash
//         } else if (mPredictedWeatherDelta < 0.0f) {
//             alertText = "RAIN";
//         } else {
//             alertText = "FAIR";
//         }