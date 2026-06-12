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