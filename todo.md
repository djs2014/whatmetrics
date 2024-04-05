field A,B,C/D,E,F/G,H,I
- props
fallback 
  Seconds to detect:
  HR related: 0 for x sec
  Power related:  0 for x sec
fallback when paused:

one field
: nr fields 3/6/9  
large field
wide field
small field

show timer/elapsed or time

fields:
grade
distance
clock
timer
elapsed time
power
power/kg
altitude
cadence
speed
hiit
vo2max
heartrate
hr zone

option: 
  show averages








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

------------------
winter:
- config field per cel 1.1, 1.2, etc..
- define grid per: large / medium / wide / small field
- fallback for hr related fields (easy to left at home)
- fallback for powermeter -> @@ 
- 


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
  - x hitt countdown start, cooldown

