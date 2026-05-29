import Toybox.Lang;
import Toybox.System;
import Toybox.Math;

class ClimbTracker {
    private var debugMode = true;
    function setDebugMode(enabled as Boolean) as Void {
        debugMode = enabled;
    }
    enum {
        STATE_FLAT,
        STATE_PENDING_CLIMB,
        STATE_ACTIVE_CLIMB,
    }

    private var currentClimbState = STATE_FLAT;
    private var distanceInState = 0.0f;
    private var lastDistance = 0.0f;

    // The climb-specific metrics we want to auto-reset
    public var currentClimbMaxGrade = 0.0f;
    public var currentClimbTotalGradeSum = 0.0f;
    public var currentClimbSamples = 0;

    // Climb detection criteria
    public var minimalClimbStartGrade = 3.0f; // Minimum grade to consider the start of a climb
    public var minimalClimbStartDistance = 30.0f; // Minimum distance to consider the start of a climb 
    public var minimalClimbStopGrade = 1.5f; // Grade below which we consider the climb to be ending
    public var minimalClimbStopDistance = 50.0f; // Distance traveled below


    function processAutoReset(currentGrade as Float, currentDistance as Float) {
        if (lastDistance == 0.0f) {
            lastDistance = currentDistance;
            return;
        }
        var distanceTraveled = currentDistance - lastDistance;
        lastDistance = currentDistance;
        if (debugMode) {
            System.println(
                "Current State: " + currentClimbState +
                ", Current Grade: " + currentGrade.format("%0.1f") +
                "%, Distance Traveled: " + distanceTraveled.format("%0.1f") + "m"
            );
        }
        switch (currentClimbState) {
            case STATE_FLAT:
                // If the road tilts up, start monitoring for a real climb
                if (currentGrade >= minimalClimbStartGrade) {
                    currentClimbState = STATE_PENDING_CLIMB;
                    distanceInState = 0.0f;
                    if (debugMode) {
                        System.println("Potential climb detected. Entering PENDING_CLIMB state.");
                    }
                }
                break;

            case STATE_PENDING_CLIMB:
                distanceInState += distanceTraveled;

                if (currentGrade < minimalClimbStartGrade) {
                    // False alarm, it was just a micro-bump. Back to flat.
                    currentClimbState = STATE_FLAT;
                    if (debugMode) {
                        System.println("False alarm. Returning to FLAT state.");
                    }
                } else if (distanceInState >= minimalClimbStartDistance) {
                    // Conformed "Big Climb"! Wipe old stats clean for this new hill.
                    resetClimbStats();
                    currentClimbState = STATE_ACTIVE_CLIMB;
                    distanceInState = 0.0f;
                    if (debugMode) {
                        System.println("Big climb detected. Entering ACTIVE_CLIMB state.");
                    }
                }
                break;

            case STATE_ACTIVE_CLIMB:
                distanceInState += distanceTraveled;

                // 1. Accumulate metrics for the current active climb
                if (currentGrade > currentClimbMaxGrade) {
                    currentClimbMaxGrade = currentGrade;
                }
                currentClimbTotalGradeSum += currentGrade;
                currentClimbSamples++;

                // 2. Check if we have flattened out or started descending
                if (currentGrade >= minimalClimbStopGrade) {
                    // Reset exit distance counter if they start climbing steeply again
                    distanceInState = 0.0f;
                } else if (distanceInState >= minimalClimbStopDistance) {
                    // User has ridden flat/downhill for minimalClimbStopDistance. The big climb is over.
                    currentClimbState = STATE_FLAT;
                    if (debugMode) {
                        System.println("Big climb ended. Returning to FLAT state.");
                    }
                }
                break;
        }
    }

    public function resetClimbStats() {
        currentClimbMaxGrade = 0.0f;
        currentClimbTotalGradeSum = 0.0f;
        currentClimbSamples = 0;
    }

    public function getAverageClimbGrade() as Float {
        if (currentClimbSamples == 0) {
            return 0.0f;
        }
        return currentClimbTotalGradeSum / currentClimbSamples;
    }
}
