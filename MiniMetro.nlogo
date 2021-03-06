;___Table of Contents__________________________________
;to be done soon (not important)
;___INITIALIZE GLOBALS_________________________________
;extensions [profiler] ;used for checking fps
globals[;created on 1/5 , used for setting up main system
  isEditing;checks if world is being edited
  trackWidth;width of track
  stationsList;array of all stations
  pathIDList;list of all paths made in order, to show proper overlap.

  isAddPath;For Breed path to tell observer if adding path
  AddPathValueA;
  AddPathValueB;
  AddPathValueColor;
  AddPathValueEdit;
  askingID;
  recentID;
  atStation;

  isGenerating;is it generating new line
  lineAsker
  isDed

  colorPalette; order of new line colors
  colorsUsed;
  colorList;list of booleans contatining colors

  lineList; list of all currently using lines
  lineThreshold;

  isSelected
  SelectedSegment

  gameOver

  isDraggingTrain;checks if a train is selected and being dragged around
  dragTrainPrevious;the state of isDraggingTrain one tick prior
  trainButton;
  trainButtonDisplay;
  playButton;
  isPaused;
  trainSpeed; how fast do trains pickup people (before including person slowdown)
  availableTrains;
                 ;stationTypes 0-3
  stationTypesUsed;What shapes are used?
  lastFrameClicked
]
;___INITIALIZE BREEDS__________________________________
breed[paths path]
paths-own[;1/5 paths are the objects that repsent a connection between 2 stations
  colorLine;color of line/ ID of line
  direction;16 directions
  bendDir; can be left or right (-1 or 1)
  beingEdited;is the path being altered?
  stationA;beginning station
  stationB;end station
  pathID;ID used to track order of rendering paths for overlap
  sIDA;unique stationID used to check if multiple lines cross the same station
  sIDB;
  finalized;checks if the path should be added to final list
  potentialStations; chain(list) of stations when joining multiple stations at once
  pathsCreated; temporary list of all paths in an editing sequence
  vertexX;vertex x and y of bend
  vertexY
  segmentA;first and latter segments
  segmentB;
  endPath?;is this path ending the line?
  endDir; direction facing stationB
  startDir; direction facing stationA
  isReal
  pathOwner;line
  RemoveLastFrame; did the path editor remove the previous frame?
  isHighlighted;is the curent line being selected?
]
breed[plasts plast]
plasts-own[;1/5 repesented endpoints (point-last = plast)
  myPlastPath
  myPlastLine
  localStation
  defX
  defY
  endType
]
breed[stations station]
stations-own[;1/4 station
  shapeType; what people get off here
  stationID;
  connectingLines; list of all lines that get here
  endPointDir; list of all endpoint directions to avoid overlap
  cLines;
  myPassengers;
  maxCapacity;
  timerThreshold;
  gameOverTimer;
]
breed[segments segment]
segments-own[;1/6
  minX
  minY
  maxX
  maxY
  initX
  initY
  endX
  endY
  segmentType; beginning or end of path
  myPath;the path that the segment's a part of
  mSeg;slope of segment
  bSeg;intercept of segment (origin lies at the center of the world)
  isVertical
  distMouse
  segmentLength
]
breed[trains train]
trains-own[;
  lineOfTrain;the line the train is on
  trainDirection; the directin the train is going on
  people; list of people on line
  trainFinalized
  myTrainLine;
             ;isRotating; is the train turning
             ;turnFrames;
             ;rotationAngle;
             ;rotationDirection;

  reachedCheckpoint;
  currentPath;
  currentSegment;
  stationIndex;
  pickupSpeed;
  myPeople;
]
breed[lines line]
lines-own[
  lineStations;list of all stations
  lineID;
  linePaths;
  isLooping;
  currentBeginning;
  currentEnd;
  endPlast;Arrow at start of line
  startPlast;Arrow at end of line
  colorID;
]
breed[numDisplays numDisplay]
numDisplays-own[
  number
]
breed[passengers passenger]
passengers-own[
  ;schedule;list AI generates
  ;Ex"
  ;getTrain (0 or 1) Line
  ;offAt
  ;getTrain (0 or 1) Line
  ;ofAt
  ;etc...
  askTrainDirection; 0 or 1
  askTrainType;
  tID;
  onTrain;
  passengerType;
  passengerStation;station of passenger
  myTrain
  ix
  iy
]
;___Set the game up__________
to setup
  ca
  reset-ticks
  set gameOver false
  ask patches[
    let gradient sqrt ((pxcor * pxcor) + (pycor * pycor))
    let p (((1 - (gradient / max-pxcor * 1.142)) * 13) + 229)
    let finalColor (list p p p)
    set pcolor finalColor
  ]
  set availableTrains 8
  set isPaused false
  set trainSpeed 30
  set colorPalette [yellow orange blue sky green brown pink magenta red]
  set colorsUsed 0
  set colorList (list (false) (false) (false) (false) (false) (false) (false) (false) (false) (false))
  set isDed false
  set lastFrameClicked false
  set isAddPath false
  set isEditing false
  set isGenerating false
  set trackWidth 30
  set lineThreshold (trackWidth / 4)
  set stationsList (list)
  set pathIDList (list)
  set stationTypesUsed (list)
  let m 0
  while [m < 10][
    let canSpawn false
    let rx random-xcor
    let ry random-ycor
    while [not canSpawn][
      set rx random-xcor
      set ry random-ycor
      ifelse any? stations[
        let nearest (min-one-of stations [distancexy rx ry])
        ask nearest[
          if (distancexy rx ry) > (trackWidth * 3) and (ry > (min-pycor + (2 * trackWidth))) and (abs(rx) < (max-pxcor - (trackWidth * 4))) and (abs(ry) < (max-pycor - (trackWidth * 4))) [
            set canSpawn true
          ]
        ]
      ][
        if (abs(rx) < (max-pxcor - (trackWidth * 4))) and (abs(ry) < (max-pycor - (trackWidth * 4)))[
          set canSpawn true
        ]
      ]
    ]
    generateStation rx ry
    set m (m + 1)
  ]
  crt 1 [
    set shape "trainButton"
    set size (trackWidth )
    set heading 0
    set color gray + 3
    setxy (-300 + (size / 2)) (-300 + (size / 2))
    set trainButton self
  ]
  crt 1 [
    set shape "pause"
    set size trackWidth
    set heading 0
    set color gray + 3
    setxy (-300 + (1.5 * size)) (-300 + (size / 2))
    set playButton self
  ]
  create-numDisplays 1[
    set trainButtonDisplay self
  ]
  ;set m 0
  ;while [m < ((length stationsList) - 1)][
  ;  generatePath (station m) (station (m + 1)) ((random 13) * 10 + 5)
  ;  set m (m + 1)
  ;]
end

;___Path Functions_________________________________

;Tests when the user clicks on a station, then initializes the updatePath procedure
to generatePath [A B line-color isEdit]
  create-paths 1 [
    set isReal true
    ifelse line-color = length colorPalette[
      set color grey
      set colorLine 1337
      set shape "stop"
      set isReal false
    ][
      set color (item line-color colorPalette)
      set colorLine line-color
    ]
    set RemoveLastFrame false
    set stationA A
    set pathID length pathIDList
    set pathIDList lput pathID pathIDList
    set recentID self
    set beingEdited isEdit

    set size (trackWidth / 3)
    set isHighlighted 0
    setxy ([xcor] of stationA) ([ycor] of stationA)
    let m 0
    ask A[
      set m length connectingLines
      set connectingLines lput myself connectingLines
    ]
    set sIDA m
    ifelse beingEdited[
      set isEditing true
      set potentialStations (list)
      set pathsCreated (list)
      set pathsCreated lput self pathsCreated
      set potentialStations lput A potentialStations
      set finalized false
    ][
      permanentPath B
    ]
  ]
end
to-report containsID [ID caller]
  let i 0
  while [i < length ([potentialStations] of caller) ][
    if  [stationID] of (item i ([potentialStations] of caller)) = ID [
      report true
    ]
    set i (i + 1)
  ]
  report false
end
;Updates the path being edited each frame it's being edited
to updatePath
  if beingEdited [;is it being edited?
    ifelse beingEdited and not(mouse-down?)[ ;if just done editing, now what?
      set isEditing false
      set isGenerating true
      set lineAsker self
      let originID ([stationID] of (item ((length potentialStations) - 1) potentialStations)); most recent station in sequence of paths
      ifelse any? stations in-radius (trackWidth / 2) with [not (containsID stationID myself)] and isReal and (not RemoveLastFrame)[; are there any stations to connect to that arent in the sequence? (used so can't have line go on same thing twice.)
        permanentPath min-one-of (stations in-radius (trackWidth / 2) with [not (containsID stationID myself)]) [distance myself]
        set atStation true
        set isAddPath true
        set AddPathValueA (item ((length potentialStations) - 1) potentialStations);
        set AddPathValueB min-one-of (stations in-radius (trackWidth / 2) with [not (containsID stationID myself)]) [distance myself]
        set potentialStations lput (min-one-of (stations in-radius (trackWidth / 2) with [not (containsID stationID myself)]) [distance myself]) potentialStations
        set AddPathValueColor colorLine
        set AddPathValueEdit false
        set isDed false
      ][
        set pathIDList remove-item ([pathID] of self) pathIDList
        let myID sIDA
        set atStation false
        set RemoveLastFrame true
        ask stationA [
          set connectingLines remove-item myID connectingLines
        ]
        if length potentialStations  = 1[
          set isGenerating false
          die
        ]
        set isDed true
      ]
    ][
      ifelse any? stations in-radius (trackWidth / 2) with [not (containsID stationID myself)] and (not atStation) and isReal[
        set isAddPath true
        set AddPathValueA (item ((length potentialStations) - 1) potentialStations);
        set AddPathValueB min-one-of (stations in-radius (trackWidth / 2) with [not (containsID stationID myself)]) [distance myself]
        set potentialStations lput (min-one-of (stations in-radius (trackWidth / 2) with [not (containsID stationID myself)]) [distance myself]) potentialStations
        set AddPathValueColor colorLine
        set AddPathValueEdit false
        set askingID self
        set atStation true
      ][
        ifelse any? stations in-radius (trackWidth / 2) with [stationID  = ([stationID] of (last [potentialStations] of myself)) ] and (length potentialStations > 1) and isReal[
          if atStation = false[
            set RemoveLastFrame true
            set potentialStations remove-item (length potentialStations - 1) potentialStations
            set pathIDList remove (last pathsCreated) pathIDList
            let lastPath (last pathsCreated)
            set pathsCreated  remove-item (length pathsCreated - 1) pathsCreated
            ask [stationA] of (lastPath)[
              set connectingLines remove (lastPath) connectingLines
            ]
            ask [stationB] of (lastPath)[
              set connectingLines remove (lastPath) connectingLines
            ]
            ask lastPath[
              die
            ]
            set atStation true
          ]
        ][
          set atStation any? stations in-radius (trackWidth / 2)
          if RemoveLastFrame and (not atStation)[
            set RemoveLastFrame false
          ]
        ]
      ]

    ]
  ]
  let sx mouse-xcor
  let sy mouse-ycor
  ifelse beingEdited[
    set direction (getDirection mouse-xcor mouse-ycor)
  ][
    set direction getDirection ([xcor] of stationB) ([ycor] of stationB)
    set sx ([xcor] of stationB)
    set sy ([ycor] of stationB)
    if segmentA = 0[
      let s self
      hatch-segments 1[
        initializeSegment ([stationA] of myself) s "A"
      ]
      hatch-segments 1[
        initializeSegment ([stationB] of myself) s "B"
      ]
    ]

  ]
  let ox xcor
  let oy ycor
  canTurn sx sy
  facexy ox oy
  set startDir heading
  let px xcor
  let py ycor
  set vertexX px
  set vertexY py
  setxy sx sy
  facexy vertexX vertexY
  set endDir (180 + heading)
  ifelse isHighlighted = 1[
    highlightLine ox oy px py isHighlighted
  ][
    highlightLine ox oy px py 0
  ]
  ifelse isHighlighted = 2[
    highlightline xcor ycor sx sy isHighlighted
  ][
    highlightline xcor ycor sx sy 0
  ]
  set color 5
  pu

end
;Finalizes the characteristics for each path once it's finished being edited
to permanentPath [B]
  let m 0
  ask B[
    set connectingLines lput myself connectingLines
    set m length connectingLines
  ]
  set stationB B
  set finalized true
  set sIDB m
end
;for testing purposes
to dealMultiline
  ask stationA[
    show [direction] of item 1 connectinglines
  ]
end
;Highlights segment when mouse is hovering over it
to highlightLine[ox oy px py highlight]
  pu
  setxy ox oy
  set pen-size (size / 2)
  ifelse isReal[
    set color (item colorLine colorPalette)
  ][
    set color gray
  ]
  pd
  setxy px py
  pu
  setxy ox oy
  set pen-size (size / 3)
  ifelse isReal[
    set color (item colorLine colorPalette) + highlight
  ][
    set color gray
  ]
  pd
  setxy px py
  pu
end
;Reports the direction each segment is facing
to-report getDirection [x y]
  ifelse beingEdited[
    setxy ([xcor] of (item ((length potentialStations) - 1) potentialStations)) ([ycor] of (item ((length potentialStations) - 1) potentialStations))
  ][
    setxy ([xcor] of stationA) ([ycor] of stationA)
  ]
  facexy x y
  report ((floor (heading / 22.5)) + 1)
end
;Draws each segments based on its endpoints
to canTurn [x y]
  ;N
  if (direction mod 16) = 1[
    setxy xcor (y - abs(x - xcor))
  ]
  if (direction mod 16) = 0[
    setxy xcor (y - abs(x - xcor))
  ]
  ;NE
  if (direction mod 16) = 2[
    setxy x (y - abs(abs(y - ycor) - abs(x - xcor)))
  ]
  if (direction mod 16) = 3[
    setxy (x - abs(abs(x - xcor) - abs(y - ycor))) y
  ]
  ;E
  if (direction mod 16) = 4[
    setxy (x - abs(y - ycor)) ycor
  ]
  if (direction mod 16) = 5[
    setxy (x - abs(y - ycor)) ycor
  ]
  ;SE
  if (direction mod 16) = 6[
    setxy (x - abs(abs(x - xcor) - abs(y - ycor))) y
  ]
  if (direction mod 16) = 7[
    setxy x (y + abs(abs(y - ycor) - abs(x - xcor)))
  ]
  ;S
  if (direction mod 16) = 8[
    setxy xcor (y + abs(x - xcor))
  ]
  if (direction mod 16) = 9[
    setxy xcor (y + abs(x - xcor))
  ]
  ;SW
  if (direction mod 16) = 10[
    setxy x (y + abs(abs(y - ycor) - abs(x - xcor)))
  ]
  if (direction mod 16) = 11[
    setxy (x + abs(abs(x - xcor) - abs(y - ycor))) y
  ]
  ;W
  if (direction mod 16) = 12[
    setxy (x + abs(y - ycor)) ycor
  ]
  if (direction mod 16) = 13[
    setxy (x + abs(y - ycor)) ycor
  ]
  ;NW
  if (direction mod 16) = 14[
    setxy (x + abs(abs(x - xcor) - abs(y - ycor))) y
  ]
  if (direction mod 16) = 15[
    setxy x (y - abs(abs(y - ycor) - abs(x - xcor)))
  ]

end
;Renders the paths
to renderPaths
  let pathCount 0
  while [pathCount < (length pathIDList)][
    ask paths with [pathid = (item pathCount pathIDList)][
      updatePath
    ]
    set pathCount (pathCount + 1)
  ]
  if isAddPath[
    generatePath AddPathValueA AddPathValueB AddPathValueColor AddPathValueEdit
    ask askingID [
      set pathsCreated lput recentID pathsCreated
    ]
  ]
  if isGenerating[
    generateLine([xcor] of ([stationA] of lineAsker)) ([ycor] of ([stationA] of lineAsker))  ([colorLine] of lineAsker) ([potentialStations] of lineAsker) ([pathsCreated] of lineAsker)
    if isDed[
      ask lineAsker[
        set beingEdited false;not being edited anymore
        die
      ]
    ]
  ]
  set isGenerating false
  set isAddPath false
end

;___Main Loop_________________________________

to go
  every 1 / 60[
    clear-drawing
    ifelse not gameOver[
      renderPaths
      updateStations
      updateplasts
      updateLines
      updateSegments
      updateTrains
      if not isPaused[
        updateTrainButton
        updatePassengers
      ]
      updatePlayButton
    ][
      ask turtles[
        die
      ]
    ]
    set lastFrameClicked mouse-down?
    tick
  ]
end

;___Station Functions_________________________________

;Creates a new station (with coordinates x and y) and declares its own stations-own variables
to generateStation [x y]
  create-stations 1 [
    setxy x y
    set size trackWidth
    set shapeType random 4
    set shape (word shapeType "station")
    if not (member? shapeType stationTypesUsed) [
      set stationTypesUsed lput shapeType stationTypesUsed
    ]
    set timerThreshold 12
    set gameOverTimer 0;
    set color white
    set stationID (length stationsList)
    set stationsList lput stationID stationsList
    set ConnectingLines (List)
    set endPointDir (list)
    set clines (list)
    set myPassengers (list)
    set maxCapacity 16
  ]
end
;Updates each station's station-own variables
to updateStations
  let isClicked false
  let clickedStation 0
  ask stations[
    ifelse (distancexy mouse-xcor mouse-ycor) < (trackWidth / 2) and mouse-down? and (color = white) and not(isEditing) and (not lastFrameClicked)[
      set clickedStation stationID
      set isClicked true
    ] [
      set color white
    ]
    if (random 360 = 0) and ((length myPassengers) < maxCapacity) and (not isPaused)[
      generatePassenger
    ]
    ifelse (gameOverTimer > 0) and ((length myPassengers) < timerThreshold)[
      set gameOverTimer (gameOverTimer - 0.01)
    ][
      if ((length myPassengers) > timerThreshold)[
        set gameOverTimer (gameOverTimer + 0.01)
      ]
      if gameOverTimer > 20[
         set gameOver true
      ]
    ]
    drawCircle ((gameOverTimer / 20) * 360) xcor ycor (size  / 2) (9.9 - ((gameOverTimer / 20) * 9.9))
  ]


  if isClicked[
    generatePath (one-of stations with [stationID = clickedStation]) 0 lowestUntaken true
  ]
end

;___Line Functions_________________________________

;Initializes generation of a line whenever a new line is created
to generateLine[x y lineColor initalLines initalPaths]
  create-lines 1[
    setxy x y
    set hidden? true
    set shape "airplane"
    set size trackWidth
    set isLooping false
    set lineID colorsUsed
    set lineStations initalLines
    set linePaths remove-item 0 initalPaths
    set colorsUsed (colorsUsed + 1)
    set currentBeginning item 0 linePaths
    set currentEnd (last linePaths)
    generatePlast currentBeginning self "s"
    generatePlast currentEnd self "e"
    if length lineStations = 0[
      decomposeLine
    ]
    set colorID lowestUntaken
    set colorList replace-item colorID colorList true
    set color (item colorID colorPalette)
    let i 0
    while [i < length lineStations][
      ask item i lineStations[

        set clines lput myself clines
      ]
      set i (i + 1)
    ]

    if availableTrains > 0[
      createTrain (item 0 lineStations) 0 1 self true true
    ]
  ]
end
;Adds a station to a line's list of stations
to addStation [newStation];unused code,planned to make lines that loop.
  ifelse (item 0 lineStations) = newStation[
    set isLooping true
  ][
    ifelse member? newStation lineStations[
      show "error, added station already exsists"
    ][
      set lineStations lput newStation lineStations
    ]

  ]
end
;Updates the lines
to updateLines
  ask lines[
    if (length linePaths) = 0[
      decomposeLine
    ]
    let i 0
    while [i < length linePaths][
      ask item i linePaths[
        set pathOwner myself
      ]
      set i i + 1
    ]
    set currentBeginning item 0 linePaths
    set currentEnd (last linePaths)
  ]
end
;Removes a line
to decomposeLine
  if endPlast != nobody[
    ask startPlast[
      ask localStation[
        set endPointDir remove ([heading] of myself) endPointDir
      ]
      die
    ]
    ask endPlast[
      ask localStation[
        set endPointDir remove ([heading] of myself) endPointDir
      ]
      die
    ]
  ]
  let i 0
  while [i < (length linePaths)][
    ask item i linePaths[
      ask segmentA[
        die
      ]
      ask segmentB[
        die
      ]
      ask stationA[
        set connectingLines (remove myself connectingLines)
      ]
      ask stationB[
        set connectingLines (remove myself connectingLines)
      ]
      die
    ]
    set i (i + 1)
  ]
  set i 0
  while [i < length lineStations][
    ask item i lineStations[

      set clines remove myself clines
    ]
    set i (i + 1)
  ]

  set colorsUsed (colorsUsed - 1)
  set colorList (replace-item colorID colorList false)
  die
end
to-report lowestUntaken
  report position false colorList
end

;_____EndStation functions___________________________

;Initializes generation of the turtle at the end of each line (known as a plast)
to generatePlast [plastPath plastLine directionChooser]
  hatch-plasts 1[
    set myplastPath plastPath
    set myPlastLine plastLine
    set hidden? false
    ifelse directionChooser = "e"[
      set heading [endDir] of myPlastPath
      ask plastLine[
        set endPlast myself
      ]
      setxy [xcor] of ([stationB] of plastPath) [ycor] of ([stationB] of plastPath)
      set localStation ([stationB] of plastPath)
      set endType true
    ][
      set heading [startDir] of myPlastPath
      ask plastLine[
        set startPlast myself
      ]
      setxy [xcor] of ([stationA] of plastPath) [ycor] of ([stationA] of plastPath)
      set localStation ([stationA] of plastPath)
      set endType false
    ]
    let isDeleting false
    ask localStation[
      let ang 1
      let dir 1
      if (member? (([heading] of myself)  mod 360) endPointDir)[
        while [(member? (([heading] of myself) mod 360) endPointDir) and (ang < 8)][
          ask myself[
            rt dir * 45 * ang
          ]
          set dir ( 0 - dir)
          set ang (ang + 1)
        ]
      ]
      ifelse (ang = 8)[
        set isDeleting true;just delete previous segment and generate new plast based off old one! (argh)
      ][
        set endPointDir lput ([heading] of myself) endPointDir
      ]
    ]
    if isDeleting[
      ask myPlastLine[
        set lineStations remove ([localStation] of myself) lineStations
        set linePaths remove ([myPlastPath] of myself) linePaths
      ]
      ask [stationA] of plastPath[
        set connectingLines remove ([myPlastPath] of myself) connectingLines
      ]
      ask [stationB] of plastPath[
        set connectingLines remove ([myPlastPath] of myself) connectingLines
      ]
      ask plastPath[
        set pathIDList remove self ([pathIDList] of myself)
        die
      ]
      ask localStation[
        set endPointDir remove ([heading] of myself) endPointDir
      ]
      ifelse length ([linePaths] of myPlastLine) > 0[
        ifelse endType[
          generatePlast (last ([linePaths] of myPlastLine)) myPlastLine "e"
          ask myPlastLine[
            ask last lineStations[
              set clines remove myself clines
            ]
          ]
        ][
          generatePlast (item 0 ([linePaths] of myPlastLine)) myPlastLine "s"
          ask myPlastLine[
            ask first lineStations[
              set clines remove myself clines
            ]
          ]
        ]
        die
      ][
        die
      ]
    ]
    fd trackWidth
    set defX xcor
    set defY ycor
  ]
end
;Updates plasts
to updatePlasts
  let isLineUpdate false
  let isLineAsker 0
  ask plasts[
    if myPlastLine = nobody[
      die
    ]
    set color [color] of myPlastLine
    setxy defX defY
    if (distancexy mouse-xcor mouse-ycor) < (trackWidth / 2)[
      set color color + 4
      if mouse-down? and (not lastFrameClicked)[
        ask myPlastLine [decomposeLine]

      ]
    ]
  ]
end

;_____Segment functions______________________________

;Generates each segment as each path is created
to initializeSegment [myStation pathI segType]
  set segmentType segType
  set myPath pathI
  set initX [xcor] of (myStation)
  set endX [vertexX] of myPath
  set initY [ycor] of (myStation)
  set endY [vertexY] of myPath
  setxy initX initY
  ifelse initX < endX
  [set minX initX]
  [set minX endX]
  ifelse initY < endY
  [set minY initY]
  [set minY endY]
  ifelse minX = initX
  [set maxX endX]
  [set maxX initX]
  ifelse initX = endX
  [set isVertical true]
  [set isVertical false]
  findEqSeg
  ask myPath[
    ifelse ([segmentType] of myself) = "A"[
      set segmentA myself
    ][
      set segmentB myself
    ]
  ]
  findEqSeg
  set hidden? true
end
;Updates each segment at every tick
to updateSegment
  if myPath = nobody[
    die
  ]
  set endX [vertexX] of myPath
  set endY [vertexY] of myPath
  ifelse initX < endX
  [set minX initX]
  [set minX endX]
  ifelse initY < endY
  [set minY initY
    set maxY endY
  ]
  [set minY endY
    set maxY initY
  ]
  ifelse minX = initX
  [set maxX endX]
  [set maxX initX]
  ifelse initX = endX
  [set isVertical true]
  [set isVertical false]
  findEqSeg
  set segmentLength (distancexy ([vertexX] of myPath) ([vertexY] of myPath))
  set distMouse distPoint mouse-xcor mouse-ycor
end
to updateSegments
  isCloseToPath
  ask segments[
    updateSegment
  ]
end
;Finds the equation of each segment in slope-intercept form
to findEqSeg
  ifelse isVertical
  [
    set mSeg initX
    set bSeg initX - (initY * mSeg)
  ]
  [
    set mSeg (initY - endY) / (initX - endX)
    set bSeg initY - (initX * mSeg)
  ]
end

;_______Dragging Trains___________________

;Distance formula, used for dragging trains
to-report distPointSeg [aEq cEq xPoint yPoint segment-item] ;aEq is equal to the slope (m), cEq is equal to the intercept (b) run by a segment.
  ifelse ([isVertical] of segment-item)[
    report abs (([initX] of segment-item) - xPoint)
  ][
    ;aEq X + cEQ = Y
    ;aeqX - 1y + ceQ = 0
    ;show (abs ((aEq * xPoint) - yPoint + cEq)) / ((aEq * aEq) + 1)
    report (abs ((aEq * xPoint) - yPoint + cEq)) / ((aEq * aEq) + 1)
  ]
end
;Highlights nearest segment
to isCloseToPath
  ask paths[
    set isHighlighted 0
  ]
  let near getNearestSegment mouse-xcor mouse-ycor
  let minDist 0
  if near != nobody[
    ask near[
      set minDist distPoint mouse-xcor mouse-ycor
    ]
  ]
  ifelse (minDist <= lineThreshold) and near != nobody[
    ask near[
      if myPath != nobody[
        set isSelected true
        set selectedSegment self
        let highlight 0
        ifelse segmentType = "A"[
          set highlight 1
        ][
          set highlight 2
        ]
        ask myPath[
          set ishighlighted highlight
        ]
      ]
    ]
  ][
    set isSelected false
    set selectedSegment nobody
  ]
end
to-report distPoint [x y]
  ifelse (x > (minX - lineThreshold)) and (x < (maxX + lineThreshold)) and (y > (minY - lineThreshold)) and (y < (maxY + lineThreshold))[
    report (distPointSeg Mseg Bseg x y self)
  ][
    report 20000
  ]
end
to-report getNearestSegment [x y];1/10 gets nearest segment form mouse (to drag trains onto lines)
  report min-one-of segments [distPoint x y]
end
;Spawns a train when the user clicks the train button and holds down, and places it on the line it is closest to if it's close enough
to createTrain [initStation initPath dir trainLine isFinalized checkPoint]
  hatch-trains 1[
    set availableTrains availableTrains - 1
    set shape "train"
    set size trackWidth * 3
    set color grey
    set myPeople (list)
    set trainFinalized isFinalized
    ;set isRotating false
    ifelse isFinalized[
      set hidden? false
      setxy ([xcor] of (item 0 ([lineStations] of trainLine))) ([ycor] of (item 0 ([lineStations] of trainLine)))
      set stationIndex (position initStation ([lineStations] of trainLine) )
      facexy [vertexX] of (item 0 ([linePaths] of trainLine)) [vertexY] of (item 0 ([linePaths] of trainLine))
      set trainDirection dir ; 0 = a, 1 = B
      set lineOfTrain trainLine
      set reachedCheckPoint checkPoint
    ][
      setxy mouse-xcor mouse-ycor
      set trainDirection 0
    ]
  ]
end

;____Train Button____________________

;Updates the train button
to updateTrainButton
  let return false
  ask trainButton[
    set return ((distancexy mouse-xcor mouse-ycor) < (size / 2)) and mouse-down? and mouse-inside? and (not lastFrameClicked)
    ask trainButtonDisplay[
      updateDisplay availableTrains [xcor] of myself ([ycor] of myself + size)
    ]
    if return[
      if availableTrains > 0[
        createTrain 0 0 0 0 false false
      ]
    ]
  ]

end
;Updates the state of each train, its passengers, etc. and makes it move
to updateTrain
  ifelse trainFinalized[
    if lineOftrain = nobody[
      trainDeath
    ]
    if (isPaused and (distancexy mouse-xcor mouse-ycor) < (size / 4)) and mouse-down? and (not lastFrameClicked) and mouse-inside?[
      trainDeath
    ]
    set color [color] of lineofTrain + 2
    if isPaused[
      stop
    ]
    ifelse not reachedCheckpoint[
      ifelse trainDirection = 0[
        ifelse distancexy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain)) < (trackWidth / 8)[
          setxy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain))
          face  [stationA] of (item stationIndex ([linePaths] of lineOfTrain))
          fd (trackWidth / 8)
        ][
          ifelse distancexy [xcor] of ([stationA] of (item stationIndex ([linePaths] of lineOfTrain))) [ycor] of ([stationA] of (item stationIndex ([linePaths] of lineOfTrain))) < (trackWidth / 8)[
            setxy [xcor] of ([stationA] of (item stationIndex ([linePaths] of lineOfTrain))) [ycor] of ([stationA] of (item stationIndex ([linePaths] of lineOfTrain)))
            set reachedCheckPoint true
            set pickupSpeed trainSpeed
            set stationIndex stationIndex - 1
            if stationIndex < 0[
              set trainDirection 1
              set stationIndex 0
            ]
            facexy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain))
            ifelse distancexy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain)) < (trackWidth / 8)[
              setxy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain))
              face  [stationA] of (item stationIndex ([linePaths] of lineOfTrain))
              fd (trackWidth / 8)
            ][
              fd (trackWidth / 8)
            ]
          ][

          ]
        ]
      ][
        ifelse distancexy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain)) < (trackWidth / 8)[
          setxy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain))
          face  [stationB] of (item stationIndex ([linePaths] of lineOfTrain))
          ifelse distancexy [xcor] of ([stationB] of (item stationIndex ([linePaths] of lineOfTrain))) [ycor] of ([stationB] of (item stationIndex ([linePaths] of lineOfTrain))) < (trackWidth / 8)[
            setxy [xcor] of ([stationB] of (item stationIndex ([linePaths] of lineOfTrain))) [ycor] of ([stationB] of (item stationIndex ([linePaths] of lineOfTrain)))
            set stationIndex stationIndex + 1
            set reachedCheckPoint true
            set pickupSpeed trainSpeed
            if stationIndex = length ([linePaths] of lineOfTrain)[
              set trainDirection 0
              set stationIndex stationIndex - 1
            ]
            facexy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain))
          ][
            fd (trackWidth / 8)
          ]
        ][
          ifelse distancexy [xcor] of ([stationB] of (item stationIndex ([linePaths] of lineOfTrain))) [ycor] of ([stationB] of (item stationIndex ([linePaths] of lineOfTrain))) < (trackWidth / 8)[
            setxy [xcor] of ([stationB] of (item stationIndex ([linePaths] of lineOfTrain))) [ycor] of ([stationB] of (item stationIndex ([linePaths] of lineOfTrain)))
            set stationIndex stationIndex + 1
            set reachedCheckPoint true
            set pickupSpeed trainSpeed
            if stationIndex = length ([linePaths] of lineOfTrain)[
              set trainDirection 0
              set stationIndex stationIndex - 1
            ]
            facexy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain))
            ifelse distancexy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain)) < (trackWidth / 8)[
              setxy [vertexX] of (item stationIndex ([linePaths] of lineOfTrain)) [vertexY] of (item stationIndex ([linePaths] of lineOfTrain))
              face  [stationB] of (item stationIndex ([linePaths] of lineOfTrain))
              fd (trackWidth / 8)
            ][
              fd (trackWidth / 8)
            ]
          ][

          ]
        ]

      ]
      fd 3
    ][
      set pickupSpeed pickupSpeed - 1
      let j self
      let foundf false
      ask min-one-of stations [distancexy ([xcor] of myself) ([ycor] of myself)][
        let i 0
        while [(i < (length myPassengers)) and (not foundf)][
          ask item i myPassengers[
            let check 0
            while [check < length askTrainDirection][
              if ((length ([myPeople] of j) < 6) and (item check askTrainDirection) = [trainDirection] of j) and ((item check askTrainType) = [lineOfTrain] of j) and (foundf = false)[
                decomposePassenger j
                set foundf true
                set i ((length [myPassengers] of myself))
              ]
              set check (check + 1)
            ]
          ]
          set i (i + 1)
        ]

      ]
        if foundf[
          set pickupSpeed (pickupSpeed + 30)
        ]
      if pickupSpeed < 0[
        set reachedCheckpoint false
        set pickupSpeed 0
      ]
    ]


  ][
    if getNearestSegment mouse-xcor mouse-ycor = nobody[
      trainDeath
    ]
    ifelse (not mouse-down?)[
      ifelse ([distMouse] of (getNearestSegment mouse-xcor mouse-ycor)) < lineThreshold[
        getTrainDirection
        set trainFinalized true
        let nearest getNearestSegment mouse-xcor mouse-ycor
        set currentSegment nearest
        set currentPath [myPath] of currentSegment
        set lineOfTrain [pathOwner] of currentPath
        set stationIndex position currentPath ([linePaths] of lineOfTrain)
        set reachedCheckPoint false
        rotate

      ][
        trainDeath
      ]
    ][
      if ([distMouse] of (getNearestSegment mouse-xcor mouse-ycor)) < lineThreshold[

        let p trainDirection
        let t heading
        getTrainDirection
        rotate
      ]
      set color 55 + (trainDirection * 30)
      setxy mouse-xcor mouse-ycor
    ]
  ]

end
;Makes each train rotate as it reaches a vertex or curve in the track
to rotate
  ifelse trainDirection = 0 [
    ifelse [segmentType] of currentSegment = "A"[
      facexy [xcor] of ([stationA] of currentPath) [ycor] of ([stationA] of currentPath)
    ][
      facexy [endX]  of currentSegment [endY] of currentSegment
    ]
  ][
    ifelse [segmentType] of currentSegment = "B"[
      facexy [xcor] of ([stationB] of currentPath) [ycor] of ([stationB] of currentPath)
    ][
      facexy [endX] of currentSegment [endY] of currentSegment
    ]
  ]
end
;Sets the direction of each train at each tick
to getTrainDirection
  let nearest (getNearestSegment mouse-xcor mouse-ycor)
  set currentSegment nearest
  set currentPath [myPath] of currentSegment
  let lengthA ([segmentLength] of ([segmentA] of ([myPath] of nearest)))
  let lengthB ([segmentLength] of ([segmentB] of ([myPath] of nearest)))
  let totalDistance lengthB + lengthA
  let distA 0
  let distB 0
  ifelse [segmentType] of nearest = "A"[
    ask nearest[
      set distA (distancexy mouse-xcor mouse-ycor)
      set distB (lengthA - distA) + lengthB
    ]
  ][
    ask nearest[
      set distB (distancexy mouse-xcor mouse-ycor)
      set distA (lengthB - distB) + lengthA
    ]
  ]
  ifelse distA > distB[
    set trainDirection 1
  ][
    set trainDirection 0
  ]
end
;Kills a train
to trainDeath
  set availableTrains availableTrains + 1
  die
end
to updateTrains
  ask trains[
    updateTrain
  ]
end
;_________Pause Button_________________________________________
;Updates the pause/play button
to updatePlayButton
  ask playButton[
    if ((distancexy mouse-xcor mouse-ycor) < (size / 2)) and mouse-inside? and mouse-down? and (not lastFrameClicked)[
      set isPaused (not isPaused)
      ifelse isPaused[
        set shape "play"
      ][
        set shape "pause"
      ]
    ]
  ]
end
;______numberDisplay____________
;Updates the train counter
to updateDisplay [num x y]
  setxy x y
  set color grey
  set size trackWidth
  set shape (word num)
end
;_____Passenger Code___________________
to test
  ask (station 0)[
    generatePassenger
  ]
end
;Spawns passengers at stations
to generatePassenger
  hatch-passengers 1[
    set onTrain False
    set color gray
    let i (random 4)
    set size trackWidth / 3
    while [(i = [shapeType] of myself) or (not (member? i stationTypesUsed))][
      set i (random 4)
    ]
    set tID length ([myPassengers] of myself)
    set shape (word i "passenger")
    set passengerType i
    setxy ([xcor] of myself + (10 + (((length ([myPassengers] of myself)) mod 8) * size) ) ) (([ycor] of myself + 20) - (size * (floor ((length ([myPassengers] of myself)) / 8))) )
    set passengerStation myself
    let k self
    ask myself[
      set myPassengers (lput k myPassengers)
    ]
    doAI passengerStation passengerType
  ]
end
;Updates the state of each passenger at each tick
to updatePassengers
  ask passengers[
    ifelse (not onTrain)[
      setxy ([xcor] of passengerStation + (10 + ((tID mod 8) * size) ) ) (([ycor] of passengerStation + 20) - (size * (floor (tID / 8))))
      set ix xcor
      set iy ycor

      if ((length ([myPassengers] of passengerStation)) > 12)[
        let rumble ((length ([myPassengers] of passengerStation)) - 12)
        setxy ix (iy + ((random (rumble * 2)) - (rumble * 1)))
      ]
      if (ticks mod 10) = 0[
          doAI passengerStation passengerType
      ]
    ][
      followTrain
    ]
  ]
end
;Makes passengers follow their train when their train comes
to followTrain
  set size trackWidth / 4
  if myTrain = nobody[
    die
  ]
  move-to myTrain
  set heading ([heading] of mytrain) + 90
  bk (([size] of mytrain) / 16)

  fd  (floor ((position self ([myPeople] of mytrain)) / 3)) * (([size] of mytrain) / 12)
  set heading ([heading] of mytrain)
  fd (([size] of mytrain) / 12)
  bk ((position self ([myPeople] of mytrain)) mod 3) * (([size] of mytrain) / 12)
  if [reachedCheckpoint] of myTrain[
    let d min-one-of stations [distancexy ([xcor] of myself) ([ycor] of myself)]
    if ([shapeType] of d) = passengerType[
       kickTrain
    ]
  ]
  set heading ([heading] of mytrain)
end
;Code that determines which way each passenger is going
to doAI [currentStation currentPassengerType];I'm aware there are better ways to do this but i'm on a time crunch right now
  let j sort-on [distancexy ([xcor] of myself) ([ycor] of myself)] (stations with [((length clines) > 0) and (shapeType = currentPassengerType)])
  let i 0
  let m "nay"
  let minDiff 99999
  let minIndex (list)
  let perferredLine (list);
  let goingDirection (list);
  while [(i < length j)][
    ask item i j[
      ifelse (sharesLine (currentStation) self) != "nope" [
        let k (sharesLine (currentStation) self)
        let dir 0
        ifelse (position (currentStation) ([lineStations] of k) > position self ([lineStations] of k))[
        ][
          set dir 1
        ]
        let diff abs ((position (currentStation) ([lineStations] of k)) - (position self ([lineStations] of k)))
        if minDiff >= diff[
          set minDiff diff
          if minDiff != diff[
            set minIndex (list)
            set perferredLine (list);
            set goingDirection (list);
          ]
          set minIndex lput i minIndex
          set goingDirection lput dir goingDirection
          set perferredLine lput k perferredLine
          ifelse dir = 0[
            set m "tobeginning"
          ][
            set m "toend"
          ]
        ]
      ][

      ]
    ]
    set i (i + 1)
  ]
  ifelse m = "nay" [
    set color red
  ][
    set color grey
  ]
  ;show m
  ;show mindiff
  ;show goingDirection
  set askTrainDirection goingDirection
  set askTrainType perferredLine
  ;show askTrainType
  ;show minIndex
end
;Makes passenger get off station and get on train when train comes
to decomposePassenger [futureTrain]
  let j tID
  ask passengerStation[
    set myPassengers remove myself myPassengers
    ask passengers with [passengerStation = myself and tID > j][
      set tID (tID - 1)
    ]
  ]
  set myTrain futureTrain
  ask myTrain[
     set myPeople (lput myself myPeople)
  ]
  set onTrain true;
end
;Makes passenger get off train at appropriate station
to kickTrain
  ask myTrain[
    set myPeople (remove myself myPeople)
  ]
  die
end
to-report sharesLine [fStation lStation]
  report listCompare ([clines] of fStation) ([clines] of lStation)
end
to-report listCompare [list1 list2]
  let i 0
  let j max (list (length list1) (length list2))
  while [i < j][
    ifelse (length list1) > (length list2)[
      if (member? (item i list1) list2)[
        let anyone  any? trains with [lineOfTrain = (item i list1)]
        if anyone[
          report item i list1
        ]
      ]
    ][
      if (member? (item i list2) list1)[
        let anyone  any? trains with [lineOfTrain = (item i list2)]
        if anyone[
          report item i list2
        ]
      ]
    ]
    set i (i + 1)
  ]
  report "nope"
end
;___misc._________
to drawCircle [i x y r c]
  let k 0
  hatch 1[
      set color c
  set pen-size (trackWidth / 6)
    while [k < i][
      setxy (x + ((sin k) * r)) (y + ((cos k) * r))
      pd
      setxy (x + ((sin (k + 1)) * r)) (y + ((cos (k + 1)) * r))
      set k (k + 1)
    ]
    die
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
195
10
804
620
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-300
300
-300
300
1
1
1
ticks
1000.0

BUTTON
11
285
74
318
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
62
251
125
284
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

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

This is a port of the game MiniMetro, which is a transit simulator.This shows the transit flow of people, and shows how som people want to arrive in specific destinations. Passengers of specific shapes go on trains and want to go the same-shaped station.For example, a circle-shaped person would want to go to a cricle-shaped station.They each have a primitive AI that only relies on connecting lines of it's station to travel.

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)
-We used a breed-oriented structure:

  Lines        Lines   Lines      Passengers
    ||         |        ||
  Stations    Trains  Endpoint                         
     |                   |
   Paths                Paths
     ||
   Segments
Using this, everything can be organized better.
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
I used plenty of features, mainly using many list functions. When updating each station,train, control system, I always use lists to keep everyting organized. I also use an object system, where I made breeds own other breeds. So a TrainLine would own all the stations,endpoints and rails, aswell as trains, and each rail has segments to get mouse detection.Each station would "own" all the connecting paths aswell. This allows the project to run smooothly and make any part of any object easily acessible.Specifically, I used the remove method a lot, which removes a certain item in a list. This is used when anything despawns or gets deleted, like deleting a line or removing a train. I also used the position method quite a lot, as I wanted to order everything with IDs, and when a old line is deleted, position is used to find the next free slot for a line. I also use the word function a lot to convert numbers to strings to retrieve turtle shapes like "1station".


## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES
-Created by Julian and Kevin

 +1/2/18    Kevin   added automatic Track development
 +1/2/18    Julian  added distance formula and segment code
 +1/3/18    Kevin   added distance tracker
 +1/4/18    Kevin   modified distance tracker
 +1/5/18    Kevin   added endpoint aspect, fixed minor bugs
 +1/5/18    Julian  added code for trains, made on-screen buttons
 +1/6/18    Kevin   fixed bugs and added minor features
 +1/6/18    Julian  fixed bugs in train code
 +1/8/18    Kevin   fixed segment bugs, added station sorting
 +1/8/18    Julian  added documentation.
 +1/9/18    Kevin   added segment detection
 +1/10/18   Kevin   added train button
 +1/11/18   Julian  added train breed
 +1/12/18   Kevin   added train initialization code
 +1/12/18   Kevin   added finshing train code
 +1/12/18   Julian  added passenger framwork
 ________________Julian is sick from here___________
 +1/13/18   Kevin   rewrote passenger code
 +1/13/18   Kevin   fixed train code
 +1/13/18   Kevin   added passengerSpawning
 +1/13/18   Kevin   added passengerPickup
 +1/14/18   Kevin   added primitive passengerAI
 +1/14/18   Kevin   added visuals for passengers on trains
 +1/14/18   Kevin   fixed passengerAI
 +1/15/18   Kevin   added stationTimer for overcrowding
 +1/15/18   Kevin   added stop for project if 20 seconds of overcrowding
 +1/15/18   Kevin   finished documentation
 +1/15/18   Kevin   realized many potentail optimizations
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

0
false
0
Rectangle -7500403 true true 0 0 300 60
Rectangle -7500403 true true 0 0 60 180
Rectangle -7500403 true true 0 240 300 300
Rectangle -7500403 true true 240 120 300 300
Rectangle -7500403 true true 0 105 60 285
Rectangle -7500403 true true 240 15 300 195

0passenger
false
0
Circle -7500403 true true 0 0 300
Circle -7500403 true true 30 30 240

0station
false
0
Circle -16777216 true false 0 0 300
Circle -1 true false 30 30 240

1
false
0
Polygon -7500403 true true 120 0 0 0 0 60 120 60 120 0
Rectangle -7500403 true true 0 240 300 300
Rectangle -7500403 true true 120 0 180 300

1passenger
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -7500403 true true 151 99 225 223 75 224

1station
false
0
Polygon -16777216 true false 150 30 15 255 285 255
Polygon -1 true false 151 99 225 223 75 224

2
false
0
Rectangle -7500403 true true 0 0 300 60
Rectangle -7500403 true true 240 60 300 180
Rectangle -7500403 true true 0 120 240 180
Rectangle -7500403 true true 0 180 60 300
Rectangle -7500403 true true 60 240 300 300

2passenger
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -7500403 true true 60 60 240 240

2station
false
0
Rectangle -16777216 true false 30 30 270 270
Rectangle -1 true false 60 60 240 240

3
false
0
Rectangle -7500403 true true 0 0 300 60
Rectangle -7500403 true true 0 120 300 180
Rectangle -7500403 true true 0 240 300 300
Rectangle -7500403 true true 240 45 300 255

3passenger
false
0
Polygon -1 true false 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108
Polygon -7500403 true true 45 120 105 165 90 240 150 195 210 240 195 165 240 120 180 120 150 45 120 120

3station
false
0
Polygon -1 true false 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108
Polygon -16777216 true false 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108
Polygon -1 true false 45 120 105 165 90 240 150 195 210 240 195 165 240 120 180 120 150 45 120 120

4
false
0
Rectangle -7500403 true true 0 0 60 180
Rectangle -7500403 true true 240 0 300 300
Rectangle -7500403 true true 60 120 240 180

5
false
0
Rectangle -7500403 true true 0 0 300 60
Rectangle -7500403 true true 0 0 60 180
Rectangle -7500403 true true 0 120 300 180
Rectangle -7500403 true true 0 240 300 300
Rectangle -7500403 true true 240 120 300 300

6
false
0
Rectangle -7500403 true true 0 0 300 60
Rectangle -7500403 true true 0 0 60 180
Rectangle -7500403 true true 0 120 300 180
Rectangle -7500403 true true 0 240 300 300
Rectangle -7500403 true true 240 120 300 300
Rectangle -7500403 true true 0 105 60 285

7
false
0
Rectangle -7500403 true true 0 0 60 150
Rectangle -7500403 true true 240 0 300 300
Rectangle -7500403 true true 60 0 240 60

8
false
0
Rectangle -7500403 true true 0 0 300 60
Rectangle -7500403 true true 0 0 60 180
Rectangle -7500403 true true 0 120 300 180
Rectangle -7500403 true true 0 240 300 300
Rectangle -7500403 true true 240 120 300 300
Rectangle -7500403 true true 0 105 60 285
Rectangle -7500403 true true 240 15 300 195

9
false
0
Rectangle -7500403 true true 0 0 300 60
Rectangle -7500403 true true 0 0 60 180
Rectangle -7500403 true true 0 120 300 180
Rectangle -7500403 true true 0 240 300 300
Rectangle -7500403 true true 240 120 300 300
Rectangle -7500403 true true 240 15 300 195

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

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

endpoint
true
0
Rectangle -7500403 true true 0 0 300 60
Rectangle -7500403 true true 120 15 180 300

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

pause
true
0
Circle -7500403 true true 2 2 297
Rectangle -1 true false 90 60 120 240
Rectangle -1 true false 180 60 210 240

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

play
true
0
Circle -7500403 true true 0 0 300
Polygon -1 true false 270 150 60 75 135 150 60 210

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

square
false
0
Rectangle -7500403 true true 30 30 270 270

stop
false
0
Circle -2674135 false false 0 0 300
Line -2674135 false 45 45 255 255
Line -2674135 false 30 60 240 270
Line -2674135 false 60 30 270 240

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

train
true
0
Rectangle -7500403 true true 90 105 90 105
Rectangle -7500403 true true 120 105 180 195
Circle -13791810 true false 135 90 30

trainbutton
true
0
Circle -7500403 true true 2 2 297
Circle -1 true false 99 54 42
Rectangle -16777216 true false 75 120 225 195
Polygon -16777216 true false 90 90 90 90 105 135 135 135 150 90 90 90 105 105 105 105 105 105 90 90 90 90 135 105 120 105 105 105 150 90 135 105 120 105 120 90 120 90 135 105 120 90 105 105
Polygon -16777216 true false 90 90 90 90 105 105 135 105 150 90 90 90
Circle -1 true false 150 30 30
Circle -1 true false 195 30 30
Circle -16777216 true false 84 174 42
Circle -16777216 true false 129 174 42
Circle -16777216 true false 174 174 42

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
NetLogo 6.0.2
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
