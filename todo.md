Dutch slope/grade settings:

1. Dynamic Window Expansion (Dampening the Wind)

On a mountain pass, you want a tight, responsive buffer (e.g., 8–10 seconds) because the gradient changes fast. On the flat countryside, you can automatically widen the regression buffer to 15 or 20 seconds. This massive window mathematically crushes sudden wind gust spikes, keeping your screen locked at a peaceful 0.0%.

2. The Speed-Based Activation Threshold

In the Netherlands, you are often moving fast horizontally but barely moving vertically. You can add a guardrail that says: If the vertical climb rate is less than a millimeter per second over a rolling window, force the regression output to an absolute zero.

// Inside your SlopeCalc class
private var mIsDutchMode = true; // Can be toggled via App Settings!

function calculateGradeVariant(rawAltitude, currentDistance, currentSpeed) as Float {
    // If Dutch Mode is enabled, we apply a low-pass threshold filter
    var calculatedSlope = calculateGrade(rawAltitude, currentDistance, currentSpeed);
    
    if (mIsDutchMode) {
        // Absolute Value Filter: If the slope is vibrating between -0.3% and +0.3%,
        // it's almost certainly just wind noise or road vibration on flat land.
        if (calculatedSlope.abs() < 0.35f) {
            return 0.0f; // Force a clean, solid flat-line on the dashboard
        }
    }
    
    return calculatedSlope;
}

The Ultimate "Dutch Grade" Metric: The Wind Incline 💨

If there are no physical mountains to climb, Dutch cyclists measure their suffering by the Headwind.

If you really want to customize this for the local geography, you could use a connected phone's weather API to check the local wind speed and direction. If you are riding directly into a 30 km/h headwind, you could code a custom dashboard metric called "Equivalent Wind Grade"—proving mathematically to your friends that your flat polder ride felt exactly like climbing an 8% alpine peak!



seconds text in grey
mDecimalsColorDay 
better color scheme
use color transform from Goals
use calculateCurrentDecimalZone for HR zone
grade optie oude methode

------------------------------
unit test -> with different speed -> same results
km/h to m/s




 - set slow speed / 10 to 15 km/h
1. The Native Way: Barometric Pressure + Speed Sensor (Reactive)
Why it lags: To prevent the gradient from violently bouncing up and down every time you ride over a pothole or a small rock, Garmin applies a heavy smoothing filter. This is why you will notice a 3 to 5-second lag when you smash into the base of a steep wall before the number climbs.

// Inside onUpdate(dc) or a 1-second timer loop:
if (info.currentAltitude != null && info.currentSpeed != null && info.currentSpeed > 0.5) {
    var deltaElevation = info.currentAltitude - prevAltitude; // Rise (meters)
    var distanceTraveled = info.currentSpeed * 1.0;          // Run (meters per 1 second)

    if (distanceTraveled > 0) {
        var instantGrade = (deltaElevation / distanceTraveled) * 100.0f;
        // Apply your own customized low-pass rolling filter here to limit noise!
    }
}

2. The Predictive Way: ClimbPro & DEM Maps (Proactive)

3. The Custom Developer Way: Connect IQ Mathematical Customization

combining Barometric Elevation Deltas + Speed Sensor Distance Data with a 3-second rolling average array remains the golden industrial standard for clean dashboard performance!


Check how to decrease memory -> string manipulation , arrays
check array length when reset/setting
enable only listeners if field active


vo2max rolling
https://biketips.com/what-is-a-good-vo2-max-by-age/

# fields

https://www.cyclingweekly.com/fitness/what-is-vam-and-can-i-use-it-to-improve-my-climbing
VAM = (vertical metres climbed X 60) / time 

TrainingPeaks VAM
VAM = (metres ascended/hour)/(Gradient Factor x 100)
Gradient factor = 2 + (% grade/10)


VAM avg x seconds
https://pedallers.com/what-is-vam-in-cycling/
Relative power output (watts/kg) = VAM (metres/hour) / (200 + 10 × % gradient)

x - ETA / ETR, time / duration -> use current average speed
x ETR 0:3 --> 0:03 leading zeros
- ETA, optimistic -> use average speed of last x minutes. (speed 0 -> normal avg)
    - rolling average x minutes - default 10 minutes..
  - icons for ETA/ETR
avg: 20 m/s
remaining distance : 2000 m
duration: 2000 / 20 = 100 sec
-> only when target distance > 0

https://stackoverflow.com/questions/48692741/how-can-i-make-all-line-endings-eols-in-all-files-in-visual-studio-code-unix


https://cyklopedia.cc/cycling-tips/normalized-power-and-variability-index/



normalized power
https://www.trainingpeaks.com/coach-blog/normalized-power-how-coaches-use/
TSS
https://www.cyclistshub.com/tools/tss-calculator/
https://www.trainingpeaks.com/learn/articles/normalized-power-intensity-factor-training-stress/

settings
 - define field in middle like gearcombo now
  
hiit 
TODO disabled when no power

fields:
vo2max
calories
energyExpenditure
total ascent
total descent
trainingeffect

---
average fields
  cadence
  heartrate
  power
  speed
  


option: 
  show averages
  show battery heartrate
  x show battery powermeter

Fallback large field
Fallback wide field









- layout
  - 1 field: 282 x 470
  - 2 field: 282 X 234
  - small field: 140 x 93 140 x 92

--------------------
https://www.trainingpeaks.com/learn/articles/normalized-power-intensity-factor-training-stress/

This TSS calculator calculates TSS based on the following formula:
TSS = (sec × NP × IF) / (FTP × 3600) × 100
Where
• sec is the workout duration in seconds
• NP is Normalized Power
• IF is the Intensity Factor calculated as the percentage of your FTP
• FTP is Functional Threshold Power
• 3600 is the number of seconds in an hour.

IF = FTP /  cur power * 100

3600 sec
NP 200
FTP 250
TSS == 64

0-50 low
50 - 150 moderate
150+ high

(60 * 200 * IF) / (250 * 3600) * 100

IF = NP / FTP 200/250  == 0.8 

== 1,3
IF = 250 / 200 == 1,25