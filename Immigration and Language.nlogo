;; BREEDS
breed [speakers speaker] ;; The people in our world are called "speakers"
undirected-link-breed [matings mating] ;; Matings between two people will be represented by a link


;; PROPERTIES
;; Speaker agents have the property of language. There are three choices for possible languages:
;; 1. "original" - This means the speaker speaks the original language monolingually
;; 2. "immigrant" - This means the speakers speaks the immigrant language monolingually
;; 3. "bilingual" - This means the speak speaks both the original and immigrant language
;;
;; Speakers also have an age, which influences when they reproduce and die.
;;
;; In addition, speakers have an "opposite-language-ability," which marks their ability to speak the
;; opposite language. This ability starts at 0 for monolingual speakers, but can increase as
;; the speaker interacts more with people who speak the opposite language. Once this
;; ability crosses certain threshold, the speaker becomes bilingual.
;;
;; Finally, "mated?" is a boolean that is true if the speaker is currently mated.
speakers-own [language-spoken age opposite-language-ability mated?]

;; Number-children represents the number of children that each mating between speakers has produced.
matings-own [number-children]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; SETUP AND GO
to setup
  clear-all
  ask patches [set pcolor 139] ;; Make the background color
  create-speakers number-citizens ;; Create a number of citizens
  [ set color magenta ;; They will have a single magenta speech bubble, indicating they speak the original language
    set language-spoken "original"
    set shape "speaker"  ]
  create-speakers number-immigrants ;; Create a number of immigrants
  [ set color 84 ;; They will have a single teal bubble, indicating they speak the immigrant language
    set language-spoken "immigrant"
    set shape "speaker"  ]
  create-speakers number-bilinguals ;; Create a number of bilinguals
  [ set shape "bilingual" ;; They have both magenta and teal bubbles, indicating that they speak both languages
    set language-spoken "bilingual"
    set color 84
  ]
  ask speakers [
    set age random 75 ;; All of the speakers in the world will have an age randomly from 0 to 75
    setxy random-xcor random-ycor ;; All of the speakers will be randomly distributed in the world
    set mated? false ;; Speakers in the world will start off being unmated with other speakers - TODO, may want to change this as we add influx immigration
    set opposite-language-ability 0
    set size 2
  ]
  reset-ticks
end

to go
  ;; For all speakers:
  ask speakers [
    age-or-die
    move
    mate
  ]
  ;; For speakers of the original language:
  ask speakers with [language-spoken = "original"] [
    learn-immigrant-language
    check-if-bilingual
  ]
  ;; For speakers of the immigrant language:
  ask speakers with [language-spoken = "immigrant"] [
    learn-original-language
    check-if-bilingual
  ]
  ;; For all matings (pairs of speakers):
  ask matings [
    produce-children
  ]
  immigration-flow
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; PROCEDURES FOR ALL SPEAKERS
to age-or-die ;; If a speakers is too old, it dies. Otherwise, its age increments.
  ifelse age > 75
    [ die ]
  [set age age + 1]
end

to move ;; Speakers wander around the country.
  right random 100
  left random 100
  forward 0.1
end

;; Mating involves creating a "mating" link between the two speaker agents.
;; If the speaker is above certain age, and the closest speaker is also a certain age, they mate if they are both single,
;; meaning if they do not already have a mating link with another speaker.
to mate
  if age >= 18 and (mated? = false) [ ;; If the speaker is above 18 and single, it will look for a mate
    if any? other speakers [
      let potential-mate min-one-of other speakers [distance myself] ;; It will consider the closest speaker as a mate
      ask potential-mate
      [ if age >= 18 and (mated? = false) ;; If the mate is above 18 and also single, they will create a mating
        [
          create-mating-with myself
          set mated? true
          ask myself [ set mated? true]
        ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; PROCEDURES FOR MONOLINGUAL SPEAKERS
;; Speakers will "talk" to their nearest turtle and if the turtle speaks the opposite language, they
;; will gain knowledge of that language by a certain amount, dependent on the age of the speaker.
;; If the speaker is under the age of 10, they will learn the language extremely quickly - based on
;; data pinpointing ages under 10 as most critical for second language acquisition
;; If the speaker is 10-18, they will still be more likely to learn but will have a harder time learning
;; After age 18, it is much harder to speakers to pick up on new languages, but they are still able to do so
;; - albeit at a much slower pace than a younger turtle
to learn-immigrant-language
  let language-of-closest-speaker "null"
  if any? other speakers [
    ask min-one-of other speakers [distance myself]
    [ set language-of-closest-speaker language-spoken ]
  ]
  if language-of-closest-speaker = "immigrant" [
    if age < 10 [
      set opposite-language-ability opposite-language-ability + 25
    ]
    if age >= 10 and age <= 18 [
      set opposite-language-ability opposite-language-ability + 5
    ]
    if age > 18 [
      set opposite-language-ability opposite-language-ability + 1
    ]
  ]
end

to learn-original-language
  let language-of-closest-speaker "null"
  if any? other speakers [
    ask min-one-of other speakers [distance myself]
    [ set language-of-closest-speaker language-spoken ]
  ]
  if language-of-closest-speaker = "original" [
    if age < 10 [
      set opposite-language-ability opposite-language-ability + 50
    ]
    if age >= 10 and age <= 18 [
      set opposite-language-ability opposite-language-ability + 25
    ]
    if age > 18 [
      set opposite-language-ability opposite-language-ability + 5
    ]
  ]
end

;; Once speakers reach a certain threshold opposite-language-ability, they become bilingual.
to check-if-bilingual
  if opposite-language-ability > bilingual-threshold [
    set language-spoken "bilingual"
    set shape "bilingual"
    set color 84
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; PROCEDURES FOR MATINGS
to produce-children
  if number-children < max-num-children ;; If the couple has not exceeded the maximum threshold of children they can birth, then proceed
  [
    let random-num-1 random 5 ;; There is a 20% chance that a child is born on this tick, representing that children are not all born at the same time
    if random-num-1 = 0 [
      let parents [who] of both-ends ;; Create a list containing the who numbers of both parents involved in the mating
      let parent-A speaker item 0 parents ;; Use who number to identify one parent
      let parent-B speaker item 1 parents ;; Use who number to identify other parent
      ask parent-A [ hatch-speakers 1
        [ ;; Create a child
          set mated? false
          set size 2
          set age 0
          set opposite-language-ability 0
          setxy ([xcor] of parent-A + [xcor] of parent-B) / 2
          ([ycor] of parent-A + [ycor] of parent-B) / 2 ;; Set location of child to halfway between the two parents

          ;; RULES FOR DETERMINING LANGUAGE OF CHILD:
          ;; If both the parents speak the original language, then the child will also speak the original language
          ;; since it is the only language that the parents know and can pass down to their child.
          if [language-spoken] of parent-A = "original" and [language-spoken] of parent-B = "original" [
            set color magenta ;; They will have a single magenta speech bubble, indicating they speak the original language
            set language-spoken "original"
            set shape "speaker"
          ]
          ;; Likewise, if both the parents speak the immigrant language, then the child will also speak the immigrant language.
          if [language-spoken] of parent-A = "immigrant" and [language-spoken] of parent-B = "immigrant" [
            set color 84 ;; They will have a single teal bubble, indicating they speak the immigrant language
            set language-spoken "immigrant"
            set shape "speaker"
          ]

          ;; If one of the parents is bilingual, and the other speaks the original language, the child will speak the
          ;; original language, because the parents must use the original language to communicate and thus the child
          ;; is most likely to acquire the language they are exposed to during early language development.
          if ([language-spoken] of parent-A = "original" and [language-spoken] of parent-B = "bilingual") or
          ([language-spoken] of parent-A = "bilingual" and [language-spoken] of parent-B = "original") [
            set color magenta ;; They will have a single magenta speech bubble, indicating they speak the original language
            set language-spoken "original"
            set shape "speaker"
          ]

          ;; Likewise, if one of the parents is bilingual, and the other speaks the immigrant language, the child
          ;; will speak the immigrant language.
          if ([language-spoken] of parent-A = "immigrant" and [language-spoken] of parent-B = "bilingual") or
          ([language-spoken] of parent-A = "bilingual" and [language-spoken] of parent-B = "immigrant") [
            set color 84 ;; They will have a single teal bubble, indicating they speak the immigrant language
            set language-spoken "immigrant"
            set shape "speaker"
          ]

          ;; If both of the parents are bilingual or if the parents speak different languages, the child
          ;; has a percent chance of being bilingual based on the "bilingual-inheritability" parameter.
          ;; Otherwise, the child will lose the immigrant language and speak only the original language.
          if ([language-spoken] of parent-A = "bilingual" and [language-spoken] of parent-B = "bilingual") or
             ([language-spoken] of parent-A = "immigrant" and [language-spoken] of parent-B = "original") or
             ([language-spoken] of parent-A = "original" and [language-spoken] of parent-B = "immigrant") [
            let random-num-2 random 100
            if random-num-2 < bilingual-inheritability [ ;; Child becomes bilingual
              set shape "bilingual" ;; They have both magenta and teal bubbles, indicating that they speak both languages
              set language-spoken "bilingual"
              set color 84
            ]
            if random-num-2 >= bilingual-inheritability [ ;; Child learns the original language
              set color magenta ;; They will have a single magenta speech bubble, indicating they speak the original language
              set language-spoken "original"
              set shape "speaker"
            ]
          ]
        ]
      ]
     set number-children number-children + 1 ;; After the child is born, increase the number of children that the mating now has
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; IMMIGRATION FLOW AND IMMIGRATION RATE PROCEDURES
;; If the "allow-immigration-flow" switch is on, the immigrants will enter the county at the rate specified by the
;; "rate-of-immigration" parameter.
to immigration-flow
  if allow-immigration-flow? [
    let random-num random 10
    if random-num < rate-of-immigration [
      create-speakers 1 ;; Create an immigrant
      [ set color 84 ;; They will have a single teal bubble, indicating they speak the immigrant language
        set language-spoken "immigrant"
        set shape "speaker"
        set age random 70 ;; All of the speakers in the world will have an age randomly from 0 to 70
        setxy random-xcor random-ycor ;; All of the speakers will be randomly distributed in the world
        set mated? false ;; Speakers in the world will start off being unmated with other speakers - TODO, may want to change this as we add influx immigration
        set opposite-language-ability 0
        set size 2
      ]
    ]
  ]
end

;; When the observer clicks the "immmigration wave" button, a number of immigrants will
;; be added to the country depending on the "immigration-wave-size" parameter
to immigration-wave
  create-speakers immigration-wave-size ;; Create X number of immigrations, with X = immigration-wave-size
  [ set color 84 ;; They will have a single teal bubble, indicating they speak the immigrant language
    set language-spoken "immigrant"
    set shape "speaker"
    set age random 70 ;; All of the speakers in the world will have an age randomly from 0 to 70
    setxy random-xcor random-ycor ;; All of the speakers will be randomly distributed in the world
    set mated? false ;; Speakers in the world will start off being unmated with other speakers - TODO, may want to change this as we add influx immigration
    set opposite-language-ability 0
    set size 2
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; PROCEDURES FOR OBSERVING AS THE MODEL RUNS
;; To watch any one of the original-language speakers in the model, if there are any original-language speakers
to watch-original
  if any? speakers with [language-spoken = "original"] [
    watch one-of speakers with [language-spoken = "original"]
    ]
end

;; To watch any one of the immigrant-language speakers in the model, if there are any immigrant-language speakers
to watch-immigrant
  if any? speakers with [language-spoken = "immigrant"] [
    watch one-of speakers with [language-spoken = "immigrant"]
    ]
end

;; To watch any one of the bilingual speakers in the model, if there are any bilingual speakers
to watch-bilingual
  if any? speakers with [language-spoken = "bilingual"] [
    watch one-of speakers with [language-spoken = "bilingual"]
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
431
57
1011
638
-1
-1
17.333333333333332
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
129
59
195
97
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
221
59
287
97
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
28
204
184
237
number-immigrants
number-immigrants
0
25
10.0
1
1
NIL
HORIZONTAL

SLIDER
29
164
183
197
number-citizens
number-citizens
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
28
244
184
277
number-bilinguals
number-bilinguals
0
25
0.0
1
1
NIL
HORIZONTAL

PLOT
1041
203
1351
338
% Immigrant-Language Monolinguals
ticks
% of speakers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"default" 1.0 0 -12345184 true "" "plot (count speakers with [language-spoken = \"immigrant\"] / count turtles) * 100"

PLOT
1042
38
1348
185
% Original-Language Monolinguals
ticks
% of speakers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"default" 1.0 0 -5825686 true "" "plot (count speakers with [language-spoken = \"original\"] / count turtles) * 100"

PLOT
1040
354
1353
496
% Immigrant-and-Original Blinguals
ticks
% of speakers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count speakers with [language-spoken = \"bilingual\"] / count turtles) * 100"

MONITOR
1293
50
1386
95
count
count speakers with [language-spoken = \"original\"]
0
1
11

MONITOR
1296
218
1390
263
count
count speakers with [language-spoken = \"immigrant\"]
17
1
11

MONITOR
1297
371
1389
416
count
count speakers with [language-spoken = \"bilingual\"]
17
1
11

MONITOR
1293
100
1386
145
% of population
(count speakers with [language-spoken = \"original\"] / count turtles) * 100
2
1
11

MONITOR
1297
268
1390
313
% of population
(count speakers with [language-spoken = \"immigrant\"] / count turtles) * 100
2
1
11

MONITOR
1298
421
1392
466
% of population
(count speakers with [language-spoken = \"bilingual\"] / count turtles) * 100
2
1
11

SLIDER
29
344
186
377
bilingual-threshold
bilingual-threshold
50
100
60.0
1
1
NIL
HORIZONTAL

TEXTBOX
31
314
218
339
Difficult level for monolingual speaker to become bilingual
11
0.0
1

TEXTBOX
32
143
222
161
Setup for Initial Population\n
11
0.0
1

SLIDER
31
557
191
590
max-num-children
max-num-children
0
5
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
33
526
183
554
Number of children each mating link can produce
11
0.0
1

SLIDER
29
459
192
492
bilingual-inheritability
bilingual-inheritability
0
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
30
424
205
466
Likelihood that a child becomes bilingual if bilingualism possible
11
0.0
1

SWITCH
211
175
407
208
allow-immigration-flow?
allow-immigration-flow?
1
1
-1000

SLIDER
211
217
385
250
rate-of-immigration
rate-of-immigration
1
10
10.0
1
1
NIL
HORIZONTAL

BUTTON
212
331
359
364
NIL
immigration-wave
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
212
373
385
406
immigration-wave-size
immigration-wave-size
0
10
3.0
1
1
NIL
HORIZONTAL

BUTTON
215
492
354
525
NIL
watch-immigrant\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
216
535
355
568
NIL
watch-original\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
215
144
433
186
Introducting immigrants that steadily enter country at the chosen rate
11
0.0
1

TEXTBOX
214
285
417
327
For use as the model is running, will introduce a one-time wave of immigration of the specified size
11
0.0
1

BUTTON
216
577
355
610
NIL
watch-bilingual
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
215
441
404
497
Observe a immigrant-language, original-language, or bilingual speaker as the model runs
11
0.0
1

PLOT
1041
509
1355
702
Histogram of Languages Spoken
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"set-plot-x-range 0 4" "plot-pen-reset\n\n;; Plotting count of original-language monolinguals\nif (any? turtles with [language-spoken = \"original\"])\n[ set-plot-pen-color magenta\n  ask patch 0 0\n  [ plot count turtles with [language-spoken = \"original\"] ] ]\n\n;; Plotting count of immigrant-language monolinguals\nif (any? turtles with [language-spoken = \"immigrant\"])\n[ set-plot-pen-color cyan\n  ask patch 0 0\n  [ plot count turtles with [language-spoken = \"immigrant\"] ] ]\n  \n;; Plotting count of bilinguals\nif (any? turtles with [language-spoken = \"bilingual\"])\n[ set-plot-pen-color black\n  ask patch 0 0\n  [ plot count turtles with [language-spoken = \"bilingual\"] ] ]\n  \n  set-plot-pen-color cyan"
PENS
"immigrant" 1.0 1 -11221820 true "" ""
"bilingual" 1.0 1 -16777216 true "" ""
"original" 1.0 0 -5825686 true "" ""

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bilingual
false
15
Circle -7500403 true false 120 120 58
Circle -1 true true 180 0 120
Polygon -1 true true 210 45 180 135 255 90 225 90
Polygon -7500403 true false 135 180 135 195 105 195 105 210 135 210 135 240 120 285 135 285 150 240 165 285 180 285 165 225 165 210 195 210 195 195 165 195 165 180 135 180 135 180
Circle -5825686 true false 210 30 60

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

speaker
false
15
Circle -7500403 true false 120 120 58
Circle -1 true true 180 0 120
Polygon -1 true true 210 45 180 135 255 90 225 90
Polygon -7500403 true false 135 180 135 195 105 195 105 210 135 210 135 240 120 285 135 285 150 240 165 285 180 285 165 225 165 210 195 210 195 195 165 195 165 180 135 180 135 180

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
