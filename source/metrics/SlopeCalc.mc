import Toybox.Lang;
import Toybox.System;
import Toybox.Math;

class SlopeCalc {
    hidden var debugMode = false;
    function setDebugMode(enabled as Boolean) as Void {
        debugMode = enabled;
    }

    function initialize() {
        // Initialize any necessary variables or state here
    }
    function setGradeWindowSize(size as Number) as Void {
        maxWindowSize = size;
    }

    function setGradeDistanceInterval(distance as Float) as Void {
        baseDistanceInterval = distance;
    }
    function setMinimalDistanceForRegression(distance as Float) as Void {
        minimalDistanceForRegression = distance;
    }

    // % grade
    function getGrade() as Float {
        return currentDisplayedGrade;
    }

    function getUserIsMoving() as Boolean {
        return userIsMoving;
    }

    private var userIsMoving = false;
    private var filteredAltitudeHistory = [] as Array<Float>;
    private var distanceHistory = [] as Array<Float>;
    private var lastTriggerDistance = 0.0f;

    // Changing the baseDistanceInterval (The Sampling Frequency)
    // Smaller interval, more responsive but more sensitive to noise. Larger interval, smoother but more lag.
    private var baseDistanceInterval = 3.0f; // Insert a node every 3 meters
    // Changing the maxWindowSize (The History Depth)
    // Smaller window, more responsive to recent changes but more sensitive to noise. Larger window, smoother but more lag.
    private var maxWindowSize = 8; // 8 samples * 3m = 24-meter rolling window
    // Sweet spots seem to be around 3-5m interval and 6-10 window size, depending on the terrain.

    private var minimalDistanceForRegression = 6.0f; // Must have at least 6 meters of total distance in the window to run regression

    private var stoppedTimer = 0; // Tracks consecutive seconds stopped
    private var currentDisplayedGrade = 0.0f;

    function calculateGrade(
        rawAltitude as Float,
        currentDistance as Float,
        currentSpeed as Float
    ) as Float {
        if (rawAltitude == 0.0f || currentDistance == 0.0f) {
            return 0.0f; // No valid data to calculate grade
        }

        if (currentSpeed != null && currentSpeed < 0.7f) {
            // Speed is too slow to trust GPS distance changes.
            // Do not log a milestone. Go straight to your stopped/decay logic.
            userHasStopped();
            return 0.0f;
        }

        var dynamicDistanceInterval = getDynamicDistanceInterval(currentSpeed);
        if (debugMode) {
            System.println("Current Speed: " + currentSpeed);
            System.println(
                "Dynamic Distance Interval: " + dynamicDistanceInterval
            );
        }
        // Always feed the raw altitude into your median filter first
        var smoothedAltitude = getSmoothedAltitude(rawAltitude);

        // Initialize distance on the very first frame
        if (lastTriggerDistance == 0.0f) {
            lastTriggerDistance = currentDistance;
        }

        // Check if we have traveled far enough to record a new milestone
        var traveledSinceLastNode = currentDistance - lastTriggerDistance;

        // THE USER IS MOVING ---
        if (traveledSinceLastNode >= dynamicDistanceInterval) {
            if (debugMode) {
                System.println(
                    "Traveled since last node: " + traveledSinceLastNode
                );
                System.println(
                    "Recording new data point. Smoothed Altitude: " +
                        smoothedAltitude +
                        ", Distance: " +
                        currentDistance
                );
            }
            stoppedTimer = 0;
            userIsMoving = true;
            // Record the data point
            filteredAltitudeHistory.add(smoothedAltitude);
            distanceHistory.add(currentDistance);

            if (filteredAltitudeHistory.size() < maxWindowSize) {
                // Not enough data yet to run regression
                return currentDisplayedGrade;
            }

            // Set the new checkpoint
            lastTriggerDistance = currentDistance;

            // Manage queue size
            if (filteredAltitudeHistory.size() > maxWindowSize) {
                filteredAltitudeHistory = filteredAltitudeHistory.slice(
                    1,
                    null
                );
                distanceHistory = distanceHistory.slice(1, null) as Array<Float>;
            }

            // If the user hasn't traveled at least 6 meters total across the entire window,
            // do not run the regression
            var oldestDistance = distanceHistory[0];
            var newestDistance = distanceHistory[distanceHistory.size() - 1];
            var totalSpan = newestDistance - oldestDistance;

            if (totalSpan < minimalDistanceForRegression) {
                return currentDisplayedGrade; // Keep old grade or return 0.0f until they move 6 meters     
            }

            currentDisplayedGrade = computeRegressionSlope();
            if (debugMode) {
                System.println(
                    "Computed Regression Slope: " + currentDisplayedGrade
                );
            }

            return currentDisplayedGrade;
        }

        // --- THE USER HAS STOPPED (OR IS MOVING INSIGNIFICANTLY) ---
        // We check if their overall speed is practically zero
        if (traveledSinceLastNode == 0.0f) {
            userHasStopped();
        }

        return currentDisplayedGrade;
    }

    // DYNAMICALLY ADJUST THE INTERVAL BASED ON SPEED
    // Lower speed = smaller distance interval (more frequent samples)
    // Higher speed = larger distance interval (more smoothing)
    private function getDynamicDistanceInterval(
        currentSpeed as Float
    ) as Float {
        var baseInterval = baseDistanceInterval; // Base interval (e.g., 3.0 meters)
        if (currentSpeed != null) {
            var speedKmh = currentSpeed * 3.6f;
            if (debugMode) {
                System.println("Current Speed (km/h): " + speedKmh);
            }
            if (speedKmh < 10.0f) {
                // Slow speed: Scale down to 50% of the base interval (e.g., 3.0 -> 1.5m)
                return baseInterval * 0.5f;
            } else if (speedKmh > 25.0f) {
                // Fast speed: Scale up to 1.5x the base interval (e.g., 3.0 -> 4.5m)
                return baseInterval * 1.5f;
            } else {
                // Medium speed (10 to 25 km/h): Smooth linear interpolation
                // Scales smoothly between 0.5x and 1.5x of your base distance
                var factor = 0.5f + (speedKmh - 10.0f) / 15.0f;
                return baseInterval * factor;
            }
        }
        return baseInterval; // Default if speed is not available
    }

    private function userHasStopped() {
        stoppedTimer++; // Increment every second this block is hit
        userIsMoving = false;
        if (debugMode) {
            System.println("User stopped: Stopped timer: " + stoppedTimer);
        }
        // Give them a 2-second grace period for GPS jitter, then start decaying
        if (stoppedTimer > 2) {
            // Smoothly decay (bleed) the grade by 50% each second
            currentDisplayedGrade = currentDisplayedGrade * 0.5f;

            // If it gets close enough to zero, snap it to absolute zero
            if ($.abs(currentDisplayedGrade) < 0.2f) {
                if (debugMode) {
                    System.println("User stopped: Grade decayed to zero.");
                }
                currentDisplayedGrade = 0.0f;

                // Clear the history so it doesn't rubber-band when they start moving again
                filteredAltitudeHistory = [] as Array<Float>;
                distanceHistory = [] as Array<Float>;
            }
        }
    }

    private function computeRegressionSlope() as Float {
        var n = filteredAltitudeHistory.size();
        var sumX = 0.0f;
        var sumY = 0.0f;
        var sumXY = 0.0f;
        var sumX2 = 0.0f;

        for (var i = 0; i < n; i++) {
            var x = distanceHistory[i];
            var y = filteredAltitudeHistory[i];

            sumX += x;
            sumY += y;
            sumXY += x * y;
            sumX2 += x * x;
        }

        var denominator = n * sumX2 - sumX * sumX;
        if (denominator == 0) {
            return 0.0f;
        }

        var slope = (n * sumXY - sumX * sumY) / denominator;
        return slope * 100.0f; // Return percentage
    }

    private var rawAltitudeHistory = [] as Array<Float>;
    private var medianWindowSize = 5;

    function getSmoothedAltitude(currentAltitude as Float) as Float {
        rawAltitudeHistory.add(currentAltitude);

        if (rawAltitudeHistory.size() > medianWindowSize) {
            rawAltitudeHistory = rawAltitudeHistory.slice(1, null);
        }
        if (debugMode) {
            System.println("Raw Altitude History: ");
            System.println(rawAltitudeHistory);
        }
        return $.getMedianValue(rawAltitudeHistory);
    }
}
