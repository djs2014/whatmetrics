# `Simple` connect IQ datafield to have some metrics :

Per different datafield size (large, wide, small) you can specify

- Layout: 
    - Datafield with 8, 6 or 4 metrics
    - Datafield with 8 or 6  metrics with same size
- The fields
- Zen mode (when on, then less details on screen)
    - off 
- Optional graphical fields (Bar position)
    - off / top / bottom

## The possible fields to choose from
- Distance
- Distance next
- Distance destination
- Grade
- Clock
- Heartrate
- Power
- Bearing
- Speed
- Altitude
- Pressure
- Pressure at sea
- Cadence
- Hiit
- Timer (without paused)
- Time elapsed
- Gear combo
- Power per weight
- Power balance
- Heartrate zone
- Gear index
- Average speed
- Average heartrate
- Average power
- Average cadence
- Normalized power
- Intensity factor 
- Training stress score
- Calores
- Estimated time arrival
- Estimated time remaining
- Vo2Max hiit
- Vo2Max profile
- Time to sun rise (of current day)
- Time to sun set (of current day)
- Time to sun rise/set (of current day)
- Time to sun rise/set continuous (of current day and next day sunrise)
- Percentage to sun rise/set (of current day)
- Percentage to sun rise/set continuous (of current day and next day sunrise)




Configuration can be done using on-device settings.

## Graphical fields (bar)

Up to 3 fields can be specified.
Zones: How many parts are in one bar.

## Fallback fields

A fallback field is activated when the actual field value doesn't make sense.
For example: For the heartrate field, if the heartrate is not available (because not using a heartrate monitor during this ride) it would display 0 the whole ride. If a fallback field is configured for this field, then it would show the value of the fallback field. (Als if the fallback field is not valid, then it could show it's fallback field, etc.. ).


## Optional Hiit field

This option needs a powermeter. If enabled, when for 5 seconds (configuration) the power is above a threshold (x% of FTP) the HIIT is started and a timer is shown. If power drops below (x% of FTP) for longer than 10 seconds (configuration) the HIIT session is stopped. If the duration was longer than 30 seconds a 'vo2Max'-score is shown. VO2Max formula used vo2max = ((6min pow er * 10.8) / weight) + 7. (https://www.michael-konczer.com/en/training/calculators/calculate-vo2max) If the duration is 6 minutes, then the score is close to a 'real' vo2max.

All HIIT options can be configured in the settings.

Vo2Max icon is the big triangle / circle in the background when enabled.
The color is based on the vo2max score. Green is good, and yellow is bad.
Based on age, see: https://www.cyclistshub.com/tools/vo2-max-calculator/


## Targets

Specify your optimal values. Based on these values the color of the icons are calculated.

- FTP this value is used to trigger the Hiit field.
- Target distance. Use for the Estimated time arrival/remaining field.
- Route as distance. When a route/course is active, use its distance as target distance.
- Target sun rise/set in minutes. How many minutes before sunrise or sunset the field is active / displayed.
    - This affects the time to sunrise fields, but NOT the perc to sunrise / sunset fields
- Focus on field. 
    - When on, show a (colored) bar around the field to focus its value.
- Focus perc of target
    - Enable the focus when close to target

# Gradient

Grade calculation.

- Changing the distance interval (The Sampling Frequency)
  Smaller interval, more responsive but more sensitive to noise. Larger interval, smoother but more lag.
  
- Changing the max window size (The History Depth)  
  Smaller window, more responsive to recent changes but more sensitive to noise. Larger window, smoother but more lag.
  
Sweet spots seem to be around 3-5m interval and 6-10 window size, depending on the terrain.
  
- Snappy: distanceInterval = 2.0f, maxWindowSize = 12.
- Balanced: distanceInterval = 3.0f, maxWindowSize = 8.
- Steady: distanceInterval = 4.0f, maxWindowSize = 6.
  
Tip: if grade stable, but takes too long to react to changes, try reducing the window size first by 2 before reducing the distance interval. This shrinks the lag.

Dynamically change the sampling frequency based on speed.

For road cyclist, set distance interval to 2.0 meter.
At slow climbing speeds, it drops down to 1.0m for hyper-responsive steep slope tracking, and expands to 3.0m on descents.

Speed Range |Typical Activity Scenario|Ideal distanceInterval
------------|-------------------------|----------------------
Fast (>20 km/h)|Cycling Flats / Descents |4.0 meters
Medium (10−20 km/h)|Moderate Cycling Climbs / Fast Running |3.0 meters
Slow (<10 km/h)|Steep Grinds / Jogging / Hiking|1.5 meters

## Colors 

- Use colors
- Colors per field. Activate only colors for specific fields.

## Fallback triggers

The `rules` when a field is active or not.

- Sec 0 power. When power is 0, how many seconds to wait when power field is inactive
- Sec 0 cadence. When cadence is 0, how many seconds to wait when cadence field is inactive
- Altitude start / end. The range when the altitude field is not active. 
    - Good for Netherlands. It will get active if we are climbing a mountain.
- Grade start / end. The range when the grade field is not active.

## Show average trend

For some fields where average is available. When enabled an arrow is shown:

- current below average: arrow to the left 
- current above average: arrow to the right

---
And there are probably more things to configure..