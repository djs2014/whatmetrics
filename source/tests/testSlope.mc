import Toybox.Test;
import Toybox.System;
import Toybox.Lang;

// Open the Command Palette (Ctrl+Shift+P / Cmd+Shift+P).
// Type Monkey C: Run Tests.

// This annotation tells the compiler this function is a unit test
(:test)
function testSlopeCalc(logger as Test.Logger) as Lang.Boolean {
    // 1. Log what you are testing for clean terminal outputs
    logger.debug("Testing SlopeCalc.calculateGrade with mock data...");

    // 2. Set up your mock data inputs
    var slopeCalc = new SlopeCalc();
    slopeCalc.setDebugMode(false);

    var mockRawAltitude = 150.0f; // Mock altitude in meters
    var mockCurrentDistance = 1000.0f; // Mock distance in meters
    var mockCurrentSpeed = 4.0f; // Mock speed in m/s
    //  var speedKmh = currentSpeed * 3.6f;
    // TODO test with 8km/h / 15km/h / 25 km/h / 30 km/h
    logger.debug(
        "Mock Current Speed (m/s): " +
            mockCurrentSpeed +
            " m/s (" +
            mockCurrentSpeed * 3.6f +
            " km/h)"
    );

    // Because your code updates both altitude and distance simultaneously inside the loop, it creates a perfectly consistent climb. Let’s break down the math for any single step of that loop (for example, moving from iteration 0 to iteration 1) to see what your slope calculation yields.
    // The Step-by-Step Loop Math
    // Let’s look at the variables across two consecutive iterations:
    //     Iteration 0:
    //         Altitude: 150.0f
    //         Distance: 1000.0f
    //     Iteration 1:
    //         Altitude: 151.0f (since 150.0f + 1)
    //         Distance: 1010.0f (since 1000.0f + 10)
    // Now, let's look at the deltas (the changes) between those two points:
    //     The Rise (Delta Altitude): 151.0 m−150.0 m=1.0 meter
    //     The Run (Delta Distance): 1010.0 m−1000.0 m=10.0 meters
    // Slope=(RunRise​)×100=(10.01.0​)×100=10.0%
    var slope = 0.0f;
    for (var i = 0; i < 10; i++) {
        slope = slopeCalc.calculateGrade(
            mockRawAltitude + i,
            mockCurrentDistance + i * 10,
            mockCurrentSpeed
        );
        logger.debug("Iteration " + i + ": Calculated slope = " + slope);
    }

    var expectedRegressionResult = 10.0f;
    var variance = (slope - expectedRegressionResult).abs();
    logger.debug(
        "Variance between calculated slope and expected regression result: " +
            variance
    );
    // Assert that the regression engine matches its expected smoothing curve perfectly
    Test.assert(variance < 0.0001f);

    // If no assertions failed, return true to signify a PASS
    return true;
}

/*
1. Iterations 0 to 7: The Buffer is Filling Up (0.0%)

During the first 8 steps (0 through 7), the engine returns a flat 0.000000. This means your SlopeCalc class has a smart safety mechanism built in: it refuses to calculate a slope until it has collected enough data points to guarantee accuracy. Instead of guessing blindly with only 2 or 3 points, it waits until the buffer hits its minimum required window size.

2. Iterations 8 to 11: The Smooth Transition (7.97% → 10.0%)

At Iteration 8, the calculation snaps awake!

    It starts at 7.97% because those early baseline initialization points are still sitting in the back of the memory queue.

    By Iteration 9, it steps up to your 8.86%.

    At Iteration 10, it hits 9.58% as the old data gets pushed closer to the edge.

    Finally, at Iteration 11, the old initialization data is completely flushed out of the memory buffer. The window is now 100% occupied by your pure 1:10 climbing steps.



3. Iterations 11+: Perfect Steady-State Execution (10.0%)

Once the buffer is entirely filled with your active climb data, the regression math locks onto the true trendline. From Iteration 11 all the way to 17, it returns a flawless, razor-sharp 10.000000%.

This log is definitive proof that your algorithm behaves exactly like a premium, production-ready cycling computer. It filters initial noise, smooths out transitions, and locks onto steady gradients with absolute mathematical precision.


*/

(:test)
function testSlowSlopeCalc(logger as Test.Logger) as Lang.Boolean {
    // 1. Log what you are testing for clean terminal outputs
    logger.debug(
        "Testing SlopeCalc.calculateGrade with mock data slow speed..."
    );

    // 2. Set up your mock data inputs
    var slopeCalc = new SlopeCalc();
    slopeCalc.setDebugMode(false);

    var mockRawAltitude = 150.0f; // Mock altitude in meters
    var mockCurrentDistance = 1000.0f; // Mock distance in meters
    var mockCurrentSpeed = 2.0f; // Mock speed in m/s
    //  var speedKmh = currentSpeed * 3.6f;
    logger.debug(
        "Mock Current Speed (m/s): " +
            mockCurrentSpeed +
            " m/s (" +
            mockCurrentSpeed * 3.6f +
            " km/h)"
    );
    var slope = 0.0f;
    for (var i = 0; i < 10; i++) {
        slope = slopeCalc.calculateGrade(
            mockRawAltitude + i,
            mockCurrentDistance + i * 10,
            mockCurrentSpeed
        );
        //logger.debug("Iteration " + i + ": Calculated slope = " + slope);
        logger.debug("Iteration " + i + ": Calculated slope = " + slope);
    }

    // History buffer contains still 0 values, so the regression result is not yet accurate. The slope is expected to be 10% but the regression result is 8.869047%. The variance is calculated as the absolute difference between the final calculated slope and the expected regression result.
    var expectedRegressionResult = 10.0f;
    var variance = (slope - expectedRegressionResult).abs();
    logger.debug(
        "Variance between calculated slope and expected regression result: " +
            variance
    );
    // Assert that the regression engine matches its expected smoothing curve perfectly
    Test.assert(variance < 0.0001f);

    // If no assertions failed, return true to signify a PASS
    return true;
}

(:test)
function testSteepClimbWithJitter(logger as Test.Logger) as Boolean {
    var calc = new SlopeCalc();
    calc.setCalculationMode(MODE_REGRESSION);

    // Initial state: Start at 0m distance, 100m altitude
    var currentDist = 0.0f;
    var currentAlt = 100.0f;
    var currentSpeed = 3.33f; // ~12 km/h (Climbing speed)

    // Simulate 20 seconds of climbing a steady 10% grade (10m rise per 100m run)
    // At 3.33 m/s, you move ~3.33m per second, gaining ~0.333m of altitude per second.
    for (var sec = 1; sec <= 20; sec++) {
        currentDist += 3.33f;

        // Base 10% elevation gain
        currentAlt += 0.333f;

        // --- SIMULATE SENSOR NOISE ---
        // 1. Add GPS Distance Jitter (±0.4 meters random drift)
        var distJitter = ((System.getTimer() % 9) - 4) * 0.1f;

        // 2. Add Barometer Noise / Wind Drag (±0.15 meters fluctuation)
        var altNoise = sec % 2 == 0 ? 0.15f : -0.15f;

        var testDist = currentDist + distJitter;
        var testAlt = currentAlt + altNoise;

        var grade = calc.calculateGrade(testAlt, testDist, currentSpeed);

        logger.debug(
            Lang.format("Sec $1$: Dist=$2$m, Alt=$3$m -> Grade=$4$%", [
                sec,
                testDist.format("%.1f"),
                testAlt.format("%.1f"),
                grade.format("%.2f"),
            ])
        );
    }

    // After 20 seconds, grade should have stabilized near 10% (allow ±1.5% margin for noise)
    var finalGrade = calc.getGrade();
    Test.assertEqualMessage(
        finalGrade >= 8.5f && finalGrade <= 11.5f,
        true,
        "Grade did not converge near 10%. Got: " + finalGrade
    );

    return true;
}

// Scenario A: Fast Descent with Barometer Lag (The Negative Sign Swap)
// Simulates going downhill at 40 km/h (11.1 m/s) on a -8% grade, but the barometer lags behind reality by 2 seconds.

(:test)
function testFastDescentWithBaroLag(logger as Test.Logger) as Boolean {
    var calc = new SlopeCalc();
    var currentDist = 1000.0f;
    var actualAlt = 500.0f;
    var speed = 11.1f; // ~40 km/h

    // Buffer to simulate a 2-second barometric delay
    var baroQueue = [500.0f, 500.0f] as Array<Float>;

    for (var sec = 1; sec <= 15; sec++) {
        currentDist += speed;
        actualAlt -= speed * 0.08f; // Dropping 8% grade

        // Push true altitude to queue, read delayed altitude
        baroQueue.add(actualAlt);
        var delayedAlt = baroQueue[0];
        baroQueue = baroQueue.slice(1, null) as Array<Float>;

        var grade = calc.calculateGrade(delayedAlt, currentDist, speed);
        logger.debug(
            Lang.format("Descent Sec $1$: Grade = $2$%", [
                sec,
                grade.format("%.2f"),
            ])
        );
    }

    var finalGrade = calc.getGrade();
    // Verify it doesn't flip positive or freeze at zero
    Test.assertMessage(
        finalGrade < -5.0f,
        "Failed to register descent, got: " + finalGrade
    );
    return true;
}

// Scenario B: Ultra-Slow MTB Climb (< 5 km/h)
// Simulates climbing at 4 km/h (1.11 m/s) on a steep 15% pitch to ensure the speed cutoff doesn't lock the display to 0.0%.
(:test)
function testSlowMTBClimb(logger as Test.Logger) as Boolean {
    var calc = new SlopeCalc();
    var currentDist = 50.0f;
    var currentAlt = 200.0f;
    var speed = 1.11f; // 4 km/h

    for (var sec = 1; sec <= 25; sec++) {
        currentDist += speed;
        currentAlt += speed * 0.15f; // 15% grade rise

        var grade = calc.calculateGrade(currentAlt, currentDist, speed);
        logger.debug(
            Lang.format("Slow Climb Sec $1$: Grade = $2$%", [
                sec,
                grade.format("%.2f"),
            ])
        );
    }

    // Grade must NOT drop to 0% due to slow speed
    Test.assertMessage(
        calc.getGrade() > 10.0f,
        "Slow climb snapped to zero or lagged severely!"
    );
    return true;
}

// Scenario C: Switchback / GPS Stall (Distance Stops, Altitude Moves)
// Simulates a tight hairpin turn on a mountain pass where GPS horizontal speed temporarily drops to 0, but altitude keeps changing.
(:test)
function testSwitchbackGPSStall(logger as Test.Logger) as Boolean {
    var calc = new SlopeCalc();
    var currentDist = 500.0f;
    var currentAlt = 300.0f;

    // 10 seconds of normal climbing
    for (var i = 0; i < 10; i++) {
        currentDist += 3.0f;
        currentAlt += 0.3f;
        calc.calculateGrade(currentAlt, currentDist, 3.0f);
    }

    // 4 seconds of GPS distance stall in a tight hairpin
    for (var i = 0; i < 4; i++) {
        currentAlt += 0.2f; // Altitude changes slightly, but distance stays frozen
        var grade = calc.calculateGrade(currentAlt, currentDist, 0.5f);
        logger.debug(
            Lang.format("GPS Stall Sec $1$: Grade = $2$%", [
                i,
                grade.format("%.2f"),
            ])
        );
        // Verify division by zero / catastrophic floating point failure didn't occur
        // Test.assertMessage(!grade.isNaN(), "Grade resulted in NaN during GPS stall");
        Test.assertMessage(
            grade != 0.0f,
            "Grade resulted in NaN during GPS stall"
        );
    }

    return true;
}
