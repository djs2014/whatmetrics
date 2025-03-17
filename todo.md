vo2max
rolling
percentile stuff -> nr
color indication
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

dark mode, graphics bar white when no color
sun rise/under graphic
ftp targer / profile?



hiit show when paused an has hits
ongoing vo2max?
hiit not active, fallback field show if bottom not filled, show from hiit?


<!-- default:  hiit when start/active/cooldown - back timer
hitt cooling down -> recovery time ...? -->
-- show vo2 max score ..
 // var yBase = y + (height / 2) - (dims_number_or_text[1] / 2); @@ TODO center text/values and rest valign center?

 function onSelectedSelection(value as Object, storageKey as String) as Void {
    Storage.setValue(storageKey, value as Number);
  }
Number -> Numeric ??

https://cyklopedia.cc/cycling-tips/normalized-power-and-variability-index/
hrv
show_graphic_fields
graphic_fields
gf_zones
$.gGraphic_fields

check array length when reset/setting
per large_field, wide ... etc.
  + graphics field def
  + height, ft, ..

// var gShow_graphic_fields as Boolean = true;
// var gGraphic_fields_line_width as Number = 7;
// var gGraphic_fields_zones as Number = 6;


TODO
      mi = new WatchUi.MenuItem("Target grade %", null, "target_grade", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);
      mi = new WatchUi.MenuItem("Target altitude meters", null, "target_altitude", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));

target if
target tts
target np == ftp?
target speed 

graphical info - levels / color/bar
IF 
TSS
HR zone
Pwr zone

[optional]
if ---
tss ---
hr 
pwr 

[avg fields bar]

power zones -> profile
layout -> option extra small fields below normal layout?
for avg values/ balance ??

show_powerbalance -> not needed?
-> if field active


normalized power
https://www.trainingpeaks.com/coach-blog/normalized-power-how-coaches-use/
TSS
https://www.cyclistshub.com/tools/tss-calculator/
https://www.trainingpeaks.com/learn/articles/normalized-power-intensity-factor-training-stress/

readme
fallback hiit / indien geen -- 

gShowPowerBalance
-> wanneer veld aanwezig is?
of include in power field?
+ check powerpedal fix 

build optimized niet ok


  // @@ TODO special field by index
        // if (mMetrics.getFrontDerailleurSize() > 0) {
        //   text_middleright = mMetrics.getFrontDerailleurSize().format("%0d");
        // }

 // @@ extra details in field .. option antizen mode
        // if (gShowPowerAverage) {
        //   text_botleft = "avg " + mMetrics.getAveragePower().format("%0d");
        // } else {
        //   text_botleft = mMetrics.getPowerPerWeight().format("%0.1f") + "/kg";
        // }

// @@ TODO, keep bottom information / stats field
        // available  = mHiitt.isHiitInProgress

size of 9

settings
 - define field in middle like gearcombo now
 - 
- Power battery time (o = operating time when max battery time is not configured, r = remaining time), format hh:mm
  
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




key large_field|0 value = 1
-> [1, ..]

------
option
Dualpower detect 
60 sec -> r/l = 0/x -> power times 2
power_dual_sec_fallback
+ underline --check dual power--
+ getHasFailingDualpower() 
 hiit --> also fix dual power failing

x Combine all menuDelegate to GeneralMenuDelegate
Show zone info larger z2
docu

Record time in zones z2 = 3 hour / week

Zone 2 -> 3 hour a week
3-8 minutes as hard as possible rest 3 - 8  --> do that 4x / week


debug
setting show batt hours j/n
bars under field / show zones hr and pwer zone
get power zones -> api?
gear combi fall back -> for ??

hr target zone
-> show average zone 1..5  < target >

show time / timer / elapsed / gear
- enum 


x power 0 for 5 seconds -> show distance

-> powermeter batt level / remaining operating time?
use bluetooth?
--save operating time when powerlevel = 5 once
calc diff 
-> less than x hours -> color

option show time in small field instead of timer


??write ugly code -> less deep nested functions -> else stack overflow errors! max 255 items in stack?




x show title when stopped and paused
asc/desc = arrows
menu setting offset small field 1 px down. var gSmallFieldYOffset as Number = 1; of calc grid/field size check total height + correctie
toggle show average power / speed

wide field under map:
option heading -> distance or distance to next (when not null).
option timer -> - distance to destination (ipv timer)



-------------------
@@ nog niet ondersteund
opacity bottom line font
- solid when paused.. 
x heartrate target zone

fall backs (after x seconds)
  pwr 0 -> distance?
  rpm 0 -> calories? / gear ratio? / pressure
  grade between -1 / 1 -> 
  altitude between x and y ->


when trans pos
-> hiit mode 
  countdown large + show timer + show score at end
  countdown large + show timer / score + show score at end
  show score at end

opacity text bottom 0-10 
odo for total asc./desc

km/miles etc..
- altitude
  + total asc/desc info

 altitude < 100 -> calories
  - energy expenditure


big screen:
 calories
 xxx gear combo -nope
 

grade -> avg grade?


- layout
  - 1 field: 282 x 470
  - 2 field: 282 X 234
  - small field: 140 x 93 140 x 92


- check memory / peak memory
- define small / wide / large / one field
- nightmode

settings:


menu:
- debug
- x ftp value --> profile
- x power per sec
- x target speed/cadence/calories/grade?/grade window size
- x hit 
  - x enabled, minimal, normal
  - x sound:
  - x hit start perc / stop perc
  - x hiit countdown start, cooldown

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