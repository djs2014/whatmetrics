import Toybox.Lang;
import Toybox.System;
import Toybox.Math;

class SlopeCalc {
    private var currentMode as SlopeCalculationMode = MODE_REGRESSION;
    private var debugMode as Boolean = false;

    // --- Simple Mode Settings ---
    private var minRun as Float = 6.0f; // Minimum run/distance (meters) to validate simple grade
    private var minRise as Float = 0.3f; // Minimum rise (meters) to validate simple grade

    // --- Regression / General Settings ---
    private var baseDistanceInterval as Float = 3.5f;
    /*
    With dynamic speed scaling multiplier ($0.5\times$ below 10 km/h, $1.5\times$ above 25 km/h):
    
    At 12 km/h (Climbing): Your effective sampling interval will be ≈2.2 meters. At 12 km/h (3.33 m/s), a new node is logged roughly every 0.7 seconds. This provides high spatial resolution on steep pinches without waiting forever for a sample.

    At 35 km/h (Descending): Your effective sampling interval scales to 5.25 meters (3.5×1.5). At 35 km/h (9.72 m/s), a new node is logged every 0.5 seconds. This prevents the window from moving past physical elevation changes faster than the barometer sensor can physically register pressure changes.

    */

    private var maxWindowSize as Number = 6;
    /*
    At 12 km/h: 6 samples $\times$ $2.2\text{m} \approx \mathbf{13.2\text{ meters total span}}$. 
    At $3.33\text{ m/s}$, the display updates grade over a rolling 4-second temporal window. 
    This feels immediate when entering a steep wall.
    
    At 35 km/h: 6 samples $\times$ $5.25\text{m} \approx \mathbf{31.5\text{ meters total span}}$. 
    At $9.72\text{ m/s}$, the span covers 3.2 seconds of travel. 8 samples at 35 km/h created a 42-meter 
    window, which caused the code to over-smooth descents and keep displaying steep downhill grades 
    long after flattening out.
    */
    private var minimalDistanceForRegression as Float = 8.0f;
    /*
    At 6.0 meters, a minor GPS horizontal drift offset of just 0.5m introduces an 8.3% error margin in your $X$-axis calculations. Raising this minimum distance to 8.0 meters filters out false grade spikes caused by stop-and-go speed surges or sharp hairpins/switchbacks where GPS horizontal 
    distance temporarily stalls.

    */
    private var medianWindowSize as Number = 3; // Reduced default to minimize lag
    /*
    Keep this at 3. Since calculateGrade() processes raw altitude at 1 Hz, a 3-sample median filter adds only 1 second of latency ($t_{-1}, t_0, t_{+1}$). A 5-sample filter creates 2 seconds of true group delay, which is the root cause of positive grades showing up early in a descent or negative grades persisting when beginning a climb.
    */

    private var userIsMoving as Boolean = false;
    private var currentDisplayedGrade as Float = 0.0f;
    private var stoppedTimer as Number = 0;

    private var filteredAltitudeHistory as Array<Float> = [] as Array<Float>;
    private var distanceHistory as Array<Float> = [] as Array<Float>;
    private var rawAltitudeHistory as Array<Float> = [] as Array<Float>;
    private var lastTriggerDistance as Float = 0.0f;

    function initialize() {}

    // --- Configuration Setters ---
    // Set the calculation mode (Regression or Simple)
    public function setCalculationMode(mode as SlopeCalculationMode) as Void {
        currentMode = mode;
    }

    public function setSensitivityProfile(
        profile as SlopeCalcSensitivity
    ) as Void {
        switch (profile) {
            case SENSITIVITY_RESPONSIVE:
                baseDistanceInterval = 2.5f;
                maxWindowSize = 5;
                break;
            case SENSITIVITY_BALANCED:
                baseDistanceInterval = 3.5f;
                maxWindowSize = 6;
                break;
            case SENSITIVITY_SMOOTH:
                baseDistanceInterval = 4.5f;
                maxWindowSize = 8;
                break;
        }
    }

    // Set thresholds for Simple Mode
    // Minimal rise (meters) and minimal run (meters) to validate simple grade calculation
    public function setSimpleModeThresholds(
        minimalRise as Float,
        minimalRun as Float
    ) as Void {
        minRise = minimalRise;
        minRun = minimalRun;
    }

    public function setDebugMode(enabled as Boolean) as Void {
        debugMode = enabled;
    }

    // // Set the window size for regression calculations (number of samples to consider)
    // public function setGradeWindowSize(size as Number) as Void {
    //     maxWindowSize = size;
    // }

    // // Set the base distance interval for sampling (meters)
    // public function setGradeDistanceInterval(distance as Float) as Void {
    //     baseDistanceInterval = distance;
    // }

    // Set the minimal distance required for regression calculations (meters)
    // public function setMinimalDistanceForRegression(distance as Float) as Void {
    //     minimalDistanceForRegression = distance;
    // }

    // Set the median window size for smoothing altitude data (number of samples to consider)
    // public function setAltitudeMedianWindowSize(size as Number) as Void {
    //     medianWindowSize = size;
    // }

    public function getGrade() as Float {
        return currentDisplayedGrade;
    }

    public function getUserIsMoving() as Boolean {
        return userIsMoving;
    }

    // --- Main Calculation Entry Point ---
    public function calculateGrade(
        rawAltitude as Float,
        currentDistance as Float,
        currentSpeed as Float
    ) as Float {
        // Validate inputs
        if (
            rawAltitude == null ||
            currentDistance == null ||
            rawAltitude == 0.0f ||
            currentDistance == 0.0f
        ) {
            return currentDisplayedGrade;
        }

        // Reduced stop speed cutoff to 0.3 m/s (~1 km/h) to avoid dropping steep slow climbs
        // hike-a-bike or 18% crawl climbs trigger the stop logic and clear history!
        if (currentSpeed != null && currentSpeed < 0.3f) {
            userHasStopped();
            return currentDisplayedGrade;
        }

        // Apply median altitude smoothing
        var smoothedAltitude = getSmoothedAltitude(rawAltitude);

        if (lastTriggerDistance == 0.0f) {
            lastTriggerDistance = currentDistance;
            return 0.0f;
        }

        var traveledSinceLastNode = currentDistance - lastTriggerDistance;

        // Check distance interval
        var dynamicInterval = getDynamicDistanceInterval(currentSpeed);

        if (traveledSinceLastNode >= dynamicInterval) {
            stoppedTimer = 0;
            userIsMoving = true;

            filteredAltitudeHistory.add(smoothedAltitude);
            distanceHistory.add(currentDistance);

            // Keep buffer within limits
            if (filteredAltitudeHistory.size() > maxWindowSize) {
                filteredAltitudeHistory =
                    filteredAltitudeHistory.slice(1, null) as Array<Float>;
                distanceHistory =
                    distanceHistory.slice(1, null) as Array<Float>;
            }

            // Update trigger point
            lastTriggerDistance = currentDistance;

            // Calculate based on selected mode
            if (currentMode == MODE_SIMPLE) {
                currentDisplayedGrade = computeSimpleGrade();
            } else {
                currentDisplayedGrade = computeRegressionSlope();
            }

            if (debugMode) {
                System.println(
                    "Mode: " +
                        currentMode +
                        " | Calculated Grade: " +
                        currentDisplayedGrade
                );
            }
        } else if (traveledSinceLastNode < 0.0f) {
            // Distance reset guard (GPS glitch/manual lap reset)
            lastTriggerDistance = currentDistance;
        }

        return currentDisplayedGrade;
    }

    // --- Mode 1: Simple Rise / Run Grade Calculation ---
    private function computeSimpleGrade() as Float {
        var size = distanceHistory.size();
        if (size < 2) {
            return currentDisplayedGrade;
        }

        var run = distanceHistory[size - 1] - distanceHistory[0]; // Total horizontal span
        var rise =
            filteredAltitudeHistory[size - 1] - filteredAltitudeHistory[0]; // Total elevation change

        if (run < minRun) {
            return currentDisplayedGrade; // Keep previous value until minimum run met
        }

        // Ignore noise where elevation change is negligible
        if (rise.abs() < minRise) {
            return 0.0f;
        }

        return (rise / run) * 100.0f;
    }

    // --- Mode 2: Linear Regression Grade Calculation ---
    private function computeRegressionSlope() as Float {
        var n = filteredAltitudeHistory.size();
        if (n < 3) {
            return currentDisplayedGrade;
        }

        var oldestDistance = distanceHistory[0];
        var totalSpan = distanceHistory[n - 1] - oldestDistance;

        if (totalSpan < minimalDistanceForRegression) {
            return currentDisplayedGrade;
        }

        var sumX = 0.0f;
        var sumY = 0.0f;
        var sumXY = 0.0f;
        var sumX2 = 0.0f;
        for (var i = 0; i < n; i++) {
            var x = distanceHistory[i] - oldestDistance;
            var y = filteredAltitudeHistory[i];

            sumX += x;
            sumY += y;
            sumXY += x * y;
            sumX2 += x * x;
        }

        var denominator = n * sumX2 - sumX * sumX;
        if (denominator == 0.0f) {
            return 0.0f;
        }

        var slope = (n * sumXY - sumX * sumY) / denominator;
        return slope * 100.0f;
    }

    private function getDynamicDistanceInterval(
        currentSpeed as Float
    ) as Float {
        if (currentSpeed == null) {
            return baseDistanceInterval; // Fallback default (3.5m)
        }

        var speedKmh = currentSpeed * 3.6f;

        // --- BRACKET 1: Steep MTB Climbing (< 7 km/h) ---
        if (speedKmh < 7.0f) {
            // Enforce a hard clamp floor at ~2.0m.
            // At 4 km/h (1.1 m/s), 2.0m takes ~1.8s per sample, which allows
            // the barometer time to register real altitude delta without noise spikes.
            return 2.0f;
        }

        // --- BRACKET 2: High Speed Descending (> 25 km/h) ---
        else if (speedKmh > 25.0f) {
            // Scale up to 1.5x base interval (5.25m if base is 3.5m)
            return baseDistanceInterval * 1.5f;
        }

        // --- BRACKET 3: Moderate Speeds (7 to 25 km/h) ---
        else {
            // Smooth linear interpolation from 2.0m at 7 km/h up to 1.5x base at 25 km/h
            var minInterval = 2.0f;
            var maxInterval = baseDistanceInterval * 1.5f;

            var progress = (speedKmh - 7.0f) / 18.0f; // 18.0 = (25 - 7)
            return minInterval + progress * (maxInterval - minInterval);
        }
    }

    private function userHasStopped() as Void {
        stoppedTimer++;
        userIsMoving = false;

        if (stoppedTimer > 3) {
            currentDisplayedGrade = currentDisplayedGrade * 0.7f; // Smoother 30% decay per sec

            if (currentDisplayedGrade.abs() < 0.2f) {
                currentDisplayedGrade = 0.0f;
                filteredAltitudeHistory = [] as Array<Float>;
                distanceHistory = [] as Array<Float>;
            }
        }
    }

    private function getSmoothedAltitude(currentAltitude as Float) as Float {
        rawAltitudeHistory.add(currentAltitude);

        if (rawAltitudeHistory.size() > medianWindowSize) {
            rawAltitudeHistory =
                rawAltitudeHistory.slice(1, null) as Array<Float>;
        }

        return getMedianValue(rawAltitudeHistory);
    }

    private function getMedianValue(array as Array<Float>) as Float {
        var len = array.size();
        if (len == 0) {
            return 0.0f;
        }

        // Make a copy to sort
        var sorted = new [len];
        for (var i = 0; i < len; i++) {
            sorted[i] = array[i];
        }

        // Insertion sort for small array
        for (var i = 1; i < len; i++) {
            var key = sorted[i];
            var j = i - 1;
            while (j >= 0 && sorted[j] > key) {
                sorted[j + 1] = sorted[j];
                j--;
            }
            sorted[j + 1] = key;
        }

        if (len % 2 == 1) {
            return sorted[len / 2];
        } else {
            return (sorted[len / 2 - 1] + sorted[len / 2]) / 2.0f;
        }
    }
}

var SlopeCalculationModeCount = 2; // incl the 0
enum SlopeCalculationMode {
    MODE_REGRESSION,
    MODE_SIMPLE,
}
var SlopeCalcSensitivityCount = 3; // incl the 0
enum SlopeCalcSensitivity {
    SENSITIVITY_RESPONSIVE,
    SENSITIVITY_BALANCED,
    SENSITIVITY_SMOOTH,
}

function getSlopeCalculationModeAsString(
    mode as SlopeCalculationMode
) as String {
    switch (mode) {
        case MODE_REGRESSION:
            return "regression";
        case MODE_SIMPLE:
            return "simple";
        default:
            return "unknown";
    }
}

function getSlopeCalcSensitivityAsString(
    sensitivity as SlopeCalcSensitivity
) as String {
    switch (sensitivity) {
        case SENSITIVITY_RESPONSIVE:
            return "responsive";
        case SENSITIVITY_BALANCED:
            return "balanced";
        case SENSITIVITY_SMOOTH:
            return "smooth";
        default:
            return "unknown";
    }
}

/*
TODO?
Stopped Decay Delay (Toggle / Selection)
Standard (3 seconds): Grace period before decaying grade to 0% when stopped.

Aggressive (1 second): Drops to 0% quickly at stoplights.

*/
