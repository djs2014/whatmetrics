import Toybox.Test;
import Toybox.System;
import Toybox.Lang;

// Open the Command Palette (Ctrl+Shift+P / Cmd+Shift+P).
// Type Monkey C: Run Tests.

// Helper function to execute any given scenario body across all mode & sensitivity combinations
// Not needed -> (:test)
function runMatrixTest(
    logger as Test.Logger,
    scenarioName as String,
    // If strict type checking (-t 2 or higher) is enabled in your monkey.jungle, Monkey C supports parameterized Method signatures:
    testFunc as
        (Method
            (
                logger as Test.Logger,
                mode as SlopeCalculationMode,
                sensitivity as SlopeCalcSensitivity
            ) as Boolean
        )
) as Boolean {
    for (var m = 0; m < SlopeCalculationModeCount; m++) {
        for (var s = 0; s < SlopeCalcSensitivityCount; s++) {
            var mode = m as SlopeCalculationMode;
            var sensitivity = s as SlopeCalcSensitivity;

            logger.debug(
                Lang.format(
                    "=== Running $1$ [Mode: $2$, Sensitivity: $3$] ===",
                    [scenarioName, mode as Number, sensitivity as Number]
                )
            );

            // Execute test scenario for this combination
            var success = testFunc.invoke(logger, mode, sensitivity);
            if (!success) {
                return false;
            }
        }
    }
    return true;
}

// -------------------------------------------------------------------
// Scenario Runners (Accept Mode & Sensitivity)
// -------------------------------------------------------------------

function runSteepClimbWithJitter(
    logger as Test.Logger,
    mode as SlopeCalculationMode,
    sensitivity as SlopeCalcSensitivity
) as Boolean {
    var calc = new SlopeCalc();
    calc.setCalculationMode(mode);
    calc.setSensitivityProfile(sensitivity);

    var currentDist = 0.0f;
    var currentAlt = 100.0f;
    var currentSpeed = 3.33f;

    for (var sec = 1; sec <= 20; sec++) {
        currentDist += 3.33f;
        currentAlt += 0.333f;

        var distJitter = ((System.getTimer() % 9) - 4) * 0.1f;
        var altNoise = sec % 2 == 0 ? 0.15f : -0.15f;

        var grade = calc.calculateGrade(
            currentAlt + altNoise,
            currentDist + distJitter,
            currentSpeed
        );
        logger.debug(
            "Iteration " + sec + ": Calculated slope = " + grade + ")"
        );
    }

    var finalGrade = calc.getGrade();
    var minGrade = 8.5f;
    var maxGrade = 11.5f;

    if (mode == MODE_SIMPLE) {
        minGrade = 8.0f;
        maxGrade = 12.0f;
    }

    Test.assertMessage(
        finalGrade >= minGrade && finalGrade <= maxGrade,
        Lang.format("Climb didn't converge. Got $1$% (Mode $2$, Sens $3$)", [
            finalGrade.format("%.2f"),
            mode as Number,
            sensitivity as Number,
        ])
    );
    return true;
}

function runFastDescentWithBaroLag(
    logger as Test.Logger,
    mode as SlopeCalculationMode,
    sensitivity as SlopeCalcSensitivity
) as Boolean {
    var calc = new SlopeCalc();
    calc.setCalculationMode(mode);
    calc.setSensitivityProfile(sensitivity);

    var currentDist = 1000.0f;
    var actualAlt = 500.0f;
    var speed = 11.1f;
    var baroQueue = [500.0f, 500.0f] as Array<Float>;

    for (var sec = 1; sec <= 15; sec++) {
        currentDist += speed;
        actualAlt -= speed * 0.08f;

        baroQueue.add(actualAlt);
        var delayedAlt = baroQueue[0];
        baroQueue = baroQueue.slice(1, null) as Array<Float>;

        var grade = calc.calculateGrade(delayedAlt, currentDist, speed);
        logger.debug(
            "Iteration " + sec + ": Calculated slope = " + grade + ")"
        );
    }

    var finalGrade = calc.getGrade();
    Test.assertMessage(
        finalGrade < -5.0f,
        Lang.format("Descent check failed, got: $1$% (Mode $2$, Sens $3$)", [
            finalGrade.format("%.2f"),
            mode as Number,
            sensitivity as Number,
        ])
    );
    return true;
}

function runSlowMTBClimb(
    logger as Test.Logger,
    mode as SlopeCalculationMode,
    sensitivity as SlopeCalcSensitivity
) as Boolean {
    var calc = new SlopeCalc();
    calc.setCalculationMode(mode);
    calc.setSensitivityProfile(sensitivity);

    var currentDist = 50.0f;
    var currentAlt = 200.0f;
    var speed = 1.11f;

    for (var sec = 1; sec <= 25; sec++) {
        currentDist += speed;
        currentAlt += speed * 0.15f;
        var grade = calc.calculateGrade(currentAlt, currentDist, speed);
        logger.debug(
            "Iteration " + sec + ": Calculated slope = " + grade + ")"
        );
    }

    Test.assertMessage(
        calc.getGrade() > 10.0f,
        Lang.format("MTB Climb snapped to zero! (Mode $1$, Sens $2$)", [
            mode as Number,
            sensitivity as Number,
        ])
    );
    return true;
}

// -------------------------------------------------------------------
// Connect IQ Runner Tests
// -------------------------------------------------------------------

(:test)
function testSteepClimbWithJitter_Matrix(logger as Test.Logger) as Boolean {
    // Correct way to reference a top-level/global function:
    var testMethod = new Lang.Method($, :runSteepClimbWithJitter);
    return runMatrixTest(logger, "SteepClimbWithJitter", testMethod);
}

(:test)
function testFastDescentWithBaroLag_Matrix(logger as Test.Logger) as Boolean {
    var testMethod = new Lang.Method($, :runFastDescentWithBaroLag);
    return runMatrixTest(logger, "FastDescentWithBaroLag", testMethod);
}

(:test)
function testSlowMTBClimb_Matrix(logger as Test.Logger) as Boolean {
    var testMethod = new Lang.Method($, :runSlowMTBClimb);
    return runMatrixTest(logger, "SlowMTBClimb", testMethod);
}
