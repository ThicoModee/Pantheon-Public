; Dependencies
#Requires AutoHotkey v2.0
#SingleInstance Force

#Include GUI\gui.ahk
#Include WebhookOptions.ahk
#Include GUI\Binaries.ahk
#Include GUI\Movements.ahk

#Include ..\..\
#Include Lib\FindText.ahk
#Include Lib\imageForCS.ahk
#Include Lib\OCR-main\Lib\OCR.ahk
#Include Lib\IsProcessElevated.ahk
#Include Lib\Gdip_ImageSearch.ahk
#Include Lib\Gdip_All.ahk
#Include Lib\Roblox.ahk

#DllLoad "Gdiplus.dll"

; Variables
global MacroStartTime := A_TickCount
global StageStartTime := A_TickCount

global hasReconnect := 0

; Define the rectangle coordinates
global startX := 100, startY := 500, endX := 700, endY := 350
global startY2 := 200, endY2 := 350
global step := 50 ; Step size for grid traversal
global successfulCoordinates := [] ; Array to store successful placements
global unsuccessfulCoordinates := []
global unsuccessfulHillCoordinates := []
global potentialPlacements := []
global filtered := []
global PathMap := []
global successThreshold := 3 ; Number of successful placements needed

global LastUUIDResponse := "", LastRequestTime := 0
global MacroState := 0 ; 0=stopped, 1=paused, 2=running 3=debug
global DEBUG := false

global placementCounts := Map()
global placementTries := Map()
global mappingCounts := Map()

global currentFails := []

global gameEnded := false

rect1 := { x: 0, y: 511, width: 60, height: 89 }
rect2 := { x: 0, y: 0, width: 260, height: 100 }
rect3 := { x: 215, y: 510, width: 405, height: 90 }
rect5 := { x: 625, y: 160, width: 180, height: 110 }
rect4 := { x: 570, y: 0, width: 194, height: 72 }
rect6 := { x: 165, y: 53, width: 490, height: 25 }
rect7 := { x: 750, y: 265, width: 50, height: 60 }

; Images

CannotPlaceUnitsArr := [CannotPlaceUnit1, CannotPlaceUnit2, CannotPlaceUnit3, CannotPlaceUnit4, CannotPlaceUnit5]

RobloxSettings := {
    MovementMode: {
        Text: "|<>*99$134.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwT7zzzzzzzzyTlwTzwzzzzz7VzzzzzzzzzbwS7zzDzzzzlsQAxksAS70kT7Vkw3VzzzwCa1iNa07AlCTkuM68nDzzz3dj9axaQrgtbwCawjBvzzzmmPmPU9bA1CNz/9j/n0TzzwYawovyNnTnaTmGPmwrzzzz9NjACzaQrwtbwZawjBzzzzn6Mb7WNbAHCQzANWM34zzzwlb3twCNnVnb7n6QD4sTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU",
        Default: "|<>*50$131.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznzzzzzzzzzzzzzzzzzz1zzTzzrTtCTzzTzzzzxjzyMzyzzzgzqNzzyzzzzzvDzwxkkMRvETAbVbh7VsRA7TzttAvavqnytSNiNaNasniTznmxrwrhbxkxvQrZtwnjQzzbY1j1jPDvVs2Pj/n1jStzzD/zRnSqTr9ryrSLZnSxnzySryvaxgziPjxCwj/axvbzwlaRqAnRzQnAswnAqBtbDzsDVvUQKsytn3tsD3UPsizzzzzzzzzzwzzznzzzzzzxzzzzzzzzzzxzzzjzzzzzznzzzzzzzzzztzzwzzzzzzzjzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk",
        Keyboard: "|<>*50$131.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzztnzzvzzzzzjzzDnzzzzzzznDzzrzzzzzTzyDbzzzzzzzYwAxcwD3dUzzwSC7SswDzz/nBnAnAr6RzjsxNaxYnDzy7jPawjDaRvzTkurZvTjTzwD0HRtSMBvrkDZZj/qD0TztCzqvmwiPrjxz/PSLj6zzznRzdrZtQrjTvyGqwjThzzzaNb7aNaljAzzwlgnAqNbzzCMTD1sQ3T5zztbQD5VsTzzzzyTzzzzzzzzzzzzzzzzzzzzxzzzzzzzzzzzzzzzzzzzzzbzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs",
    },
    CameraMode: {
        Text: "|<>*100$103.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz3zzzzzzzyDXzzbzzz0zzzzzzzz7VzznzzzDwC37VkkzXksS1kzzjwX0HaMGDkuMa8nDzrztaQrgzbsRBtSPrzvzUnCM2S3wgawjA1zxzaNbBzCNyGHSLazzyTrAnazbQz9Nj/nTzzUN6Nn4nYTaAlA1WTzsQ3AtktkDn6QD4sTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
        Follow: "|<>*49$56.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz0zvTzzzzznzyrzzzzzwz3hknCzzzDaPNYnDzznvmqwgHzzw2whj+IzzzDj/PmhTzznvmqwX7zzwyNhaMlzzzDkvQDCTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU",
        CameraToggle: "|<>*52$103.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzkzzzzzzy0zzzzTzzznDzzzzzztzzzzjzzznz3cVkuMRsS3Ur3zzvzBn6nANitaNaPAzzxzyPr/qTnRvSrhjTzyzsBvY1T1iwjPqk7zzTvaxmzjQrSLhvPzzzbxnStTriPjPqxhzzztaljQaPqBnAnAqNzzy70riMRs6wD5lPVzzzzzzzzzzzzzyzjzzzzzzzzzzzzzzaNbzzzzzzzzzzzzzzsS7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy",
    }
}

bitmaps := Map(), bitmaps.CaseSense := 0
base64 :=
    "iVBORw0KGgoAAAANSUhEUgAAAGQAAAASBAMAAABft2a7AAAAElBMVEU5Oz38/Pz8/f39/f3+/v7///+Pg9IaAAAALElEQVR42mMYBcMGCAoKCikbQ4ELFIRCQQiU72wMBUqCgoIMoSSDUS100AIAwSaP+Z3P8L8AAAAASUVORK5CYII="
bitmaps["disconnected"] := Gdip_BitmapFromBase64(&base64)

mapPatterns := Map(
    "Ant Kingdom (Midnight)", AntKingdomMidnight,
    "Sacred Planet", SacredPlanet, ;Movement needed
    "Strange Town", StrangeTown, ;Movement needed
    "Ruined City (The Menace)", RuinedCityMenace,
    "Cursed Festival", CursedFestival,
    "Future City (Tyrant's Invasion)", FutureCityTyrantsInvasion,
    "Storm Hideout", StormHideout, ;Movement needed
    "Future City", FutureCity, ;Movement needed
    "Nightmare Train", NightmareTrain,
    "Sand Village", SandVillage,
)

; Instances
global RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"

; On startup
;CheckForUpdates()
SendMode "Event"
AddToLog("Macro initialized.")

; Functions
BetterClick(x, y, LR := "Left") { ; credits to yuh for this, lowk a life saver
    MouseMove(x, y)
    MouseMove(1, 0, , "R")
    MouseClick(LR, -1, 0, , , , "R")
    Sleep(50)
}

PlaceUnit(x, y, slot := 1, index := 1) {
    global filtered
    SendInput(slot)
    Sleep 50
    CoordMode("Mouse", "Client")
    BetterClick(x, y)
    Sleep 50
    SendInput("q")

    sleep 100
    if IsPlacementSuccessful(index, slot) {
        Sleep 15
        return true
    }
    return false
}

FindAndClickColor(targetColor := 0x006783, searchArea := [0, 0, A_ScreenWidth, A_ScreenHeight]) {
    ; Extract the search area boundaries
    x1 := searchArea[1], y1 := searchArea[2], x2 := searchArea[3], y2 := searchArea[4]

    ; Perform the pixel search
    if (PixelSearch(&foundX, &foundY, x1, y1, x2, y2, targetColor, 0)) {
        ; Color found, click on the detected coordinates
        BetterClick(foundX, foundY, "Right")
        ;AddToLog("Color found and clicked at: X" foundX " Y" foundY)
        return true

    }
}

isFullScreen(WinTitle) {
    WinGetPos(&x, &y, &width, &height, WinTitle)
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight

    if (x = 0 && y = 0 && width = screenWidth && height = screenHeight) {
        return true
    } else {
        return false
    }
}

SetupMacro() {
    if WinExist(RobloxWindow) {
        if (isFullScreen(RobloxWindow)) {
            SendInput("{F11}")
            Sleep(200)
        }
        WinActivate(RobloxWindow)
        Sleep 50
        FetchPos()
        Sleep 50
        RobloxPos()
        Sleep 50
    }
}

PauseMacro() {
    if MacroState != 0
        if A_IsPaused {
            AddToLog("Macro Resumed")
            ActivateRoblox()
            UpdateMacroState(2 + DEBUG)
        } else {
            AddToLog("Macro Paused")
            ; Suspend Movement
            SendInput("{A Up}")
            UpdateMacroState(1)
        }
    Pause -1
}

UpdateMacroState(state) { ; 0=stopped, 1=paused, 2=running 3=debug
    global MacroState
    MacroState := state

    if MacroState == 0
        color := 0xFF5B55
    else if MacroState == 1
        color := 0xFF9C55
    else if MacroState == 2
        color := 0x55FF5B
    else if macroState == 3
        color := 0x5585FF

    StatusIndicatorH.Value := 'HBITMAP: ' . DrawStatus(20, color)
}

InitializeMacro() {
    global sessionTime := A_TickCount
    UpdateMacroState(2 + DEBUG)
    StartStatsUpdate()
    TabCtrl.Choose("Status")

    for i, v1 in unitUpgradePrioritydropDowns {
        for j, v2 in unitUpgradePrioritydropDowns {
            if (i < j && v1.Text == v2.Text) {
                foundDuplicate := true
                StopStatsUpdate()
                MsgBox("Duplicate found in your upgrade priorities. Error: ERR_DUPLICATE_PRIORITY", "Error", "+0x1000")
                return
            }
        }
    }

    if WinExist(RobloxWindow) {
        FetchPos()
        Sleep 50
        RobloxPos()
        WinActivate(RobloxWindow)
        Sleep 100
    }
    else {
        StopStatsUpdate()
        MsgBox("Your ROBLOX must be open in order to start the macro. Error: ERR_RBLX_NOT_OPEN", "Error", "+0x1000",)
        return
    }

    if (ok := FindText(&X, &Y, 746, 476, 862, 569, 0, 0, AreasText)) {
        GoToRaids()
    }
    else {
        StopStatsUpdate()
        MsgBox("You must wait for the icons to load before starting the macro. Error: ERR_AA_NOT_FOUND", "Error",
            "+0x1000",)
        updateMacroState(0)
        return
    }

}

SetDefaultKeyboard(localeID) {
    static SPI_SETDEFAULTINPUTLANG := 0x005A, SPIF_SENDWININICHANGE := 2
    Lan := DllCall("LoadKeyboardLayout", "Str", Format("{:08x}", LocaleID), "Int", 0)
    binaryLocaleID := Buffer(4, 0)
    NumPut("UInt", LocaleID, binaryLocaleID)
    DllCall("SystemParametersInfo", "UInt", SPI_SETDEFAULTINPUTLANG, "UInt", 0, "Ptr", binaryLocaleID, "UInt",
        SPIF_SENDWININICHANGE)
    for hwnd in WinGetList()
        PostMessage 0x50, 0, Lan, , hwnd
}

DetectMap() {
    loop {
        for mapName, pattern in mapPatterns {
            if (ok := FindText(&X, &Y, 10, 90, 415, 160, 0, 0, pattern)) {
                AddToLog("Map detected: " mapName)
                return mapName
            }
        }

        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart) or (ok := FindText(&X, &Y, 340, 537, 468, 557, 0,
            0, Yen))) {
            AddToLog("Loaded in, No map detected")
            return "N/A"
        }

        DisconnectCheck()
    }
}

EnterRaids(retry := false) {
    HandlePopups()
    
    Sleep(500)

    BetterClick(765, 474) ; Areas Button
    Sleep(1000)
    BetterClick(495, 410) ; Raids Button
    Sleep(1000)
    MoveToPortal()
    Sleep(5500)

    MouseMove(785, 208) ; Move to scrollbar
    loop 15 {
        if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, RaidMapText[RaidMapFM])) {
            FindTextClass().ScreenToWindow(&newX, &newY, X, Y - 32)
            BetterClick(newX, newY)
            break
        }
        if retry {
            SendInput("{WheelUp}")            
        } else {
            SendInput("{WheelDown}")           
        }
        Sleep(750)
    }

    Sleep(1000)

    BetterClick(RaidStageCoords[RaidMapFM].x, RaidStageCoords[RaidMapFM].y) ; Click raid stage

    Sleep(1000)

    EnterMap()

    if !LoadedLoop(RaidMaps[RaidMapFM], true) {
        EnterRaids(true)
    }
}

HandlePopups() {
    loop 5 {
        if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, PopupClose)) {
            FindTextClass().ScreenToWindow(&newX, &newY, X, Y - 32)
            BetterClick(newX, newY)
        }
        sleep(100)
    }
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Close)) {
        FindTextClass().ScreenToWindow(&newX, &newY, X, Y - 32)
        BetterClick(newX, newY)
    }
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Close2)) {
        FindTextClass().ScreenToWindow(&newX, &newY, X, Y - 32)
        BetterClick(newX, newY)
    }
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, DailyLogin)) {
        ;BetterClick(410, 425)
        BetterClick(400, 390) ; Client
    }
}

MoveToPortal() {
    global startMoveTime := A_TickCount
    SetTimer(MoveTowardsW, 100)    
}

EnterMap() {
    BetterClick(400, 430) ; Click Select
    Sleep(500)
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, MatchmakingPopup)) {
        BetterClick(336, 323) ; Click Play Here
    }
    Sleep(1000)
    BetterClick(400, 460) ; Click Start
}

GoToRaids() {
    global placementCounts := Map()
    global placementTries := Map()
    global mappingCounts := Map()
    global filtered := []
    SendInput ("{Tab}")
    Sleep(200)
    EnterRaids()
}

AfterGame() {
    global placementCounts := Map()
    global placementTries := Map()
    global mappingCounts := Map()
    global filtered := []
    DetectedMap := DetectMap()
    LoadedLoop(DetectedMap)
}

StopMacro() {
    Reload()
}

IsPlacementSuccessful(index, slot) {
    Sleep PlacementSpeed
    if (ok := FindText(&X, &Y, 78, 182, 400, 451, 0, 0, UnitExistence)) {
        AddToLog("Unit placed")
        BetterClick(329, 184) ; close upg menu
        return true
    }
    else if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Priority)) {
        AddToLog("Unit placed")
        BetterClick(329, 184) ; close upg menu
        return true
    }
    else if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Eye)) {
        AddToLog("Unit placed")
        BetterClick(329, 184) ; close upg menu
        return true
    }
    return false
}

GetWindowCenter(WinTitle) {
    x := 0 y := 0 Width := 0 Height := 0
    WinGetPos(&X, &Y, &Width, &Height, WinTitle)

    centerX := X + (Width / 2)
    centerY := Y + (Height / 2)

    return { x: centerX, y: centerY, width: Width, height: Height }
}

isInsideRect(rect, x, y) {
    if (x >= rect.x && x <= rect.x + rect.width
        && y >= rect.y && y <= rect.y + rect.height) {
        return true
    }

    return false
}

equipUnit(slot := 1) {
    SendInput(slot)
    MouseMove(565, 563)
}

IsCoordInUnsuccessful(coordX, coordY) {
    for coord in unsuccessfulCoordinates {
        if (coord.x = coordX && coord.y = coordY) {
            return true
        }
    }
    return false
}

IsHillCoordInUnsuccessful(coordX, coordY) {
    for coord in unsuccessfulHillCoordinates {
        if (coord.x = coordX && coord.y = coordY) {
            return true
        }
    }
    return false
}

IsCoordInSuccessful(coordX, coordY) {
    for coord in successfulCoordinates {
        if (coord.x = coordX && coord.y = coordY) {
            return true
        }
    }
    return false
}

isInsideAnyRect(x, y) {
    for index in [1, 2, 3, 4, 5, 6, 7] {
        rect := %"rect" index%

        if (isInsideRect(rect, x, y)) {
            return true
        }
    }
    return false
}

RepeatString(str, count) {
    result := ""
    loop count
        result .= str
    return result
}

DumpObject(obj, indent := 0) {
    output := ""
    indentStr := RepeatString("  ", indent)

    if IsObject(obj) {
        for key, value in obj {
            if IsObject(value) {
                output .= indentStr . key ":`n" . DumpObject(value, indent + 1)
            } else {
                output .= indentStr . key ": " value "`n"
            }
        }
    } else {
        output := indentStr . obj "`n"
    }

    return output
}

FilterUnique(array, successfulCoordinates, currentFails) {
    uniqueArray := []
    seen := Map()

    excluded := Map()
    for item in successfulCoordinates {
        key := Format("{},{}", item.x, item.y)
        excluded.Set(key, true)
    }
    for item in currentFails {
        key := Format("{},{}", item.x, item.y)
        excluded.Set(key, true)
    }

    for item in array {
        if !item.HasProp("x") || !item.HasProp("y") {
            MsgBox("Invalid item: " DumpObject(item))
            continue
        }

        key := Format("{},{}", item.x, item.y)
        if (!seen.Has(key) && !excluded.Has(key)) {
            seen.Set(key, true)
            uniqueArray.Push(item)
        }
    }

    return uniqueArray
}

isInCurrentFails(x, y) {
    for i, value in currentFails {
        if value.x = x && value.y = y {
            return true
        }
    }

    return false
}

Placement(map) {
    AddToLog("starting placements")
    global successfulCoordinates, maxedCoordinates, filtered, currentFails, gameEnded, mappingCounts
    successfulCoordinates := [] ; Reset successfulCoordinates for each run
    maxedCoordinates := []
    global PathMap := []
    ordered := []
    mappingLoops := 100

    mappingCounts.Clear()

    ; Iterate through all slots (1 to 6)
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := UnitEnabled.Get(slotNum)
        placements := placementFM.Get(slotNum)
        unitType := TypeFM.Get(slotNum)
        upgrades := UpgFM.Get(slotNum)

        if !(enabled == 1) {
            continue
        }

        if unitType == 3 { ; Hill
            AddToLog("Slot " slotNum " is a hill slot.")
            SendInput("{" StrReplace(PathMappingDDL.Text, "Unit ", "") "}")
            MouseMove(785, 550)
            global PathMap := []
            loop mappingLoops {
                MapPath(map, true)
            }
            filtered := DrawPath(unitType)
            hill := true
        } else {
            if slotNum != 1 && UnitEnabled.Get(slotNum - 1) == 1 && TypeFM.Get(slotNum - 1) == 3 {
                AddToLog("Previous slot was a Hill unit, remapping path")
                SendInput("{" StrReplace(PathMappingDDL.Text, "Unit ", "") "}")
                MouseMove(785, 550)
                global PathMap := []
                loop mappingLoops {
                    MapPath(map, false)
                }
                filtered := DrawPath(unitType)
            }
            hill := false
        }
        filtered := DrawPath(unitType)

        currentTries := 0

        ; Skip if the slot is not enabled

        AddToLog("Starting placements for Slot " slotNum " with " placements " placements.")

        placementCounts.Set(slotNum, 0)
        placementTries.Set(slotNum, 0)
        mappingCounts.Set(slotNum, 0)

        ; Continue placement for the current slot
        while (placementCounts.Get(slotNum) < placements && placementTries.Get(slotNum) < 25) {
            if unitType == 4 {
                if ordered.Length <= 0 {
                    if mappingCounts.Get(slotNum) >= 5 {
                        AddToLog("Path mapping attempts exceeded 5, skipping to next unit")
                        SendInput("{q}")
                        break
                    }
                    SendInput("{" StrReplace(PathMappingDDL.Text, "Unit ", "") "}")
                    MouseMove(785, 550)
                    global PathMap := []
                    loop mappingLoops {
                        MapPath(map, unitType == 3)
                    }
                    filtered := DrawPath(unitType)
                    mappingCounts.Set(slotNum, mappingCounts.Get(slotNum) + 1)
                }
            } else {
                if filtered.Length <= 0 {
                    if mappingCounts.Get(slotNum) >= 5 {
                        AddToLog("Path mapping attempts exceeded 5, skipping to next unit")
                        SendInput("{q}")
                        break
                    }
                    SendInput("{" StrReplace(PathMappingDDL.Text, "Unit ", "") "}")
                    MouseMove(785, 550)
                    global PathMap := []
                    loop mappingLoops {
                        MapPath(map, unitType == 3)
                    }
                    filtered := DrawPath(unitType)
                    mappingCounts.Set(slotNum, mappingCounts.Get(slotNum) + 1)
                }
            }

            if unitType == 4 {
                ordered := FindClosestOrder(filtered)

                for i, coord in ordered {
                    /*
                    if unitType != 3 {
                        index := -A_Index
                        coord:= filtered[index]
                    } */
                    foundX := coord.x
                    foundY := coord.y

                    if (IsCoordInSuccessful(foundX, foundY) || isInsideAnyRect(foundX, foundY) || foundX < 0 || foundY <
                    30) {
                        try {
                            ordered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        currentFails.Push({ x: foundX, y: foundY })
                        ;AddToLog("coord either in successful or intersects with blocked rectangles")
                        continue
                    }

                    AddToLog("placing at x" Floor(foundX) " y" Floor(foundY) ". currently on try " placementTries.Get(
                        slotNum))

                    if gameEnded == true {
                        break 2
                    }

                    if PlaceUnit(foundX, foundY, slotNum, i) {
                        placementCounts.Set(slotNum, placementCounts.Get(slotNum) + 1)
                        try {
                            ordered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        successfulCoordinates.Push({ x: FoundX, y: FoundY, slot: "slot_" slotNum }) ; Track successful placements
                    } else {
                        try {
                            ordered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        placementTries.Set(slotNum, placementTries.Get(slotNum) + 1)
                        currentFails.Push({ x: foundX, y: foundY })
                    }

                    if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) { ; USE ABILITY IF OFF
                        BetterClick(373, 237)
                    }

                    WinActivate(RobloxWindow)
                    SendInput("q")
                    isMatchFinished() ; next
                    BetterClick(565, 563) ; move mouse

                    /*if ShouldStopUpgrading(1) {
                        AddToLog("Stopping due to finding lobby  condition.")
                        return LobbyLoop()
                    }*/
                    if placementCounts.Get(slotNum) >= placements {
                        if unitType == 4 {
                            InfiniteBuff(slotNum)
                            Sleep(200)
                            BetterClick(328, 186)
                        }
                        break
                    }

                    DisconnectCheck()
                }
                else {
                    if (currentTries >= 1) {
                        AddToLog("Failed to find path, going to next unit")
                        SendInput("{q}")
                        break
                    }
                    AddToLog("Path not found, current try: " currentTries)
                    currentTries += 1
                }
                DisconnectCheck()
            } else {
                for i, coord in filtered {
                    /*
                    if unitType != 3 {
                        index := -A_Index
                        coord:= filtered[index]
                    } */
                    foundX := coord.x
                    foundY := coord.y

                    if (IsCoordInSuccessful(foundX, foundY) || isInsideAnyRect(foundX, foundY) || foundX < 0 || foundY <
                    30) {
                        try {
                            filtered.RemoveAt(i)
                        }
                        catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        currentFails.Push({ x: foundX, y: foundY })
                        ;AddToLog("coord either in successful or intersects with blocked rectangles")
                        continue
                    }

                    AddToLog("placing at x" Floor(foundX) " y" Floor(foundY) ". currently on try " placementTries.Get(
                        slotNum))

                    if gameEnded == true {
                        break 2
                    }

                    if PlaceUnit(foundX, foundY, slotNum, i) {
                        placementCounts.Set(slotNum, placementCounts.Get(slotNum) + 1)
                        try {
                            filtered.RemoveAt(i)
                        }
                        catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        successfulCoordinates.Push({ x: FoundX, y: FoundY, slot: "slot_" slotNum }) ; Track successful placements
                    } else {
                        try {
                            filtered.RemoveAt(i)
                        }
                        catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        placementTries.Set(slotNum, placementTries.Get(slotNum) + 1)
                        currentFails.Push({ x: foundX, y: foundY })
                    }

                    if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) { ; USE ABILITY IF OFF
                        BetterClick(373, 237)
                    }

                    WinActivate(RobloxWindow)
                    SendInput("q")
                    isMatchFinished() ; next
                    BetterClick(565, 563) ; move mouse

                    /*if ShouldStopUpgrading(1) {
                        AddToLog("Stopping due to finding lobby  condition.")
                        return LobbyLoop()
                    }*/
                    if placementCounts.Get(slotNum) >= placements {
                        if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) {
                            while (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) {
                                Sleep(100)
                            }
                        }
                        if unitType == 4 {
                            InfiniteBuff(slotNum)
                            Sleep(200)
                            BetterClick(328, 186)
                        }
                        break
                    }

                    DisconnectCheck()
                }
                else {
                    if (currentTries >= 1) {
                        AddToLog("Failed to find path, going to next unit")
                        SendInput("{q}")
                        break
                    }
                    AddToLog("Path not found, current try: " currentTries)
                    currentTries += 1
                }
                DisconnectCheck()
            }

        }

        AddToLog("Completed " placementCounts.Get(slotNum) " placements for Slot " slotNum ".")
        ; Upgrades Priority unit types inbetween placements

        DisconnectCheck()
    }

    UpgradeUnits()

    AddToLog("All slot placements and upgrades completed.")
    while gameEnded == false {
        BetterClick(328, 186)
        isMatchFinished()
        ShouldStopUpgrading()
        Sleep(500)
    }
}

coordIsInBounds(x, y) {
    return x > 0 && y > 0 && x <= 770 && y <= 580
}

MapPath(map := "Planet Greenie", isHill := false) {
    if map = "N/A" {
        map := "Planet Greenie"
    }
    global PathMap, currentFails
    if !isHill {
        if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Paths.Get(map))) {
            for i, coord in ok {
                FindTextClass().ScreenToWindow(&X, &Y, coord.x, coord.y)
                if (PathMap.Length >= 300) {
                    break
                }
                if (!isInPathMap(X, Y) && !isInCurrentFails(X, Y) && coordIsInBounds(X, Y)) {
                    PathMap.Push({ x: X, y: Y - 32 })
                }
            }
        }
    } else {
        if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Hills.Get(map))) {
            for i, coord in ok {
                FindTextClass().ScreenToWindow(&X, &Y, coord.x, coord.y)
                if (PathMap.Length >= 200) {
                    break
                }
                if (!isInPathMap(X, Y) && !isInCurrentFails(X, Y) && coordIsInBounds(X, Y)) {
                    PathMap.Push({ x: X, y: Y - 32 })
                }
            }
        }
    }
}

isInPathMap(x, y) {
    for i, coord in PathMap {
        if (coord.x = x && coord.y = y) {
            return true
        }
    }
    return false
}

DrawPath(unitType) {
    global PathMap, currentFails, DEBUG
    if PathMap.Length == 0 {
        return []
    }

    if DEBUG {
        hDC := DllCall("GetDC", "Ptr", mainGui.Hwnd, "Ptr")
        DllCall("gdiplus.dll\GdipCreateFromHDC", "Ptr", hDC, "Ptr*", &pGraphics := 0)
        DllCall("Gdiplus.dll\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)

        if unitType == 3 { ; Hill
            DllCall("Gdiplus.dll\GdipCreatePen1", "UInt", 0xFF0000FF, "Float", 2, "Int", 2, "Ptr*", &pPen := 0) ; BLUE: 0xFF0000FF
        } else {
            DllCall("Gdiplus.dll\GdipCreatePen1", "UInt", 0xFF66FF66, "Float", 2, "Int", 2, "Ptr*", &pPen := 0) ; Green: 0xFF66FF66
        }

        PathPointsDEBUG := FindClosestOrder(PathMap)

        OffsetPointsDEBUG := []

        loop PathPointsDEBUG.Length - 1 {
            x1 := PathPointsDEBUG[A_Index].x, y1 := PathPointsDEBUG[A_Index].y
            x2 := PathPointsDEBUG[A_Index + 1].x, y2 := PathPointsDEBUG[A_Index + 1].y

            dx := x2 - x1
            dy := y2 - y1
            len := Sqrt(dx * dx + dy * dy)

            if len = 0
                continue

            px := dy / len * 32
            py := -dx / len * 32 ; DONT REMOVE THIS, THIS CALCULATES PERPENDICULAR VECTOR, CHANGE 30 HERE AND BELOW FOR OFFSET BETWEEN POINTS

            offset1DEBUG := { x: x1 + px, y: y1 + py }
            offset2DEBUG := { x: x1 - px, y: y1 - py }

            if IsValidOffset(offset1DEBUG, OffsetPointsDEBUG)
                OffsetPointsDEBUG.Push(offset1DEBUG)
            if IsValidOffset(offset2DEBUG, OffsetPointsDEBUG)
                OffsetPointsDEBUG.Push(offset2DEBUG)

            DllCall("Gdiplus.dll\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", x1, "Float", y1, "Float", x2,
                "Float", y2)
            for i, point in OffsetPointsDEBUG {
                DrawCircle(pGraphics, point.x, point.y, 5, pPen)
            }
        }
    }

    if (unitType == 4) {
        PathPoints := FindClosestOrder(PathMap)
    } else {
        PathPoints := SortByDistance(PathMap, unitType)
    }

    OffsetPoints := []

    loop PathPoints.Length - 1 {
        x1 := PathPoints[A_Index].x, y1 := PathPoints[A_Index].y
        x2 := PathPoints[A_Index + 1].x, y2 := PathPoints[A_Index + 1].y

        dx := x2 - x1
        dy := y2 - y1
        len := Sqrt(dx * dx + dy * dy)

        if len = 0
            continue

        px := dy / len * 32
        py := -dx / len * 32 ; DONT REMOVE THIS, THIS CALCULATES PERPENDICULAR VECTOR, CHANGE 30 HERE AND BELOW FOR OFFSET BETWEEN POINTS

        offset1 := { x: x1 + px, y: y1 + py }
        offset2 := { x: x1 - px, y: y1 - py }

        if IsValidOffset(offset1, OffsetPoints)
            OffsetPoints.Push(offset1)
        if IsValidOffset(offset2, OffsetPoints)
            OffsetPoints.Push(offset2)
    }

    return OffsetPoints
}

IsValidOffset(point, points) {
    for _, p in points {
        if Sqrt((p.x - point.x) ** 2 + (p.y - point.y) ** 2) < 32
            return false
    }
    return true
}

DrawCircle(pGraphics, x, y, radius, pPen) {
    DllCall("Gdiplus.dll\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", x - radius, "Float", y - radius,
        "Float", radius * 2, "Float", radius * 2)
}

GetDistance(x, y, centerX, centerY) {
    return Sqrt((x - centerX) ** 2 + (y - centerY) ** 2)
}

CalculateDistance(coord, center) {
    return Sqrt((coord.x - center.x) ** 2 + (coord.y - center.y) ** 2)
}

SortByDistance(arr, unitType) { ; TYPES: DPS=1 Ground=2 Hill=3 Buff=4 Farm=5
    sortOrder := (unitType == 3) ? 1 : ((unitType == 1) ? 1 : -1)
    center := { x: 400, y: 288 }

    loop arr.Length - 1 {
        swapped := false
        loop arr.Length - A_Index {
            i := A_Index
            if (CalculateDistance(arr[i], center) - CalculateDistance(arr[i + 1], center)) * sortOrder > 0 {
                temp := arr[i]
                arr[i] := arr[i + 1]
                arr[i + 1] := temp
                swapped := true
            }
        }
        if !swapped
            break
    }

    return arr
}

FindClosestOrder(PathMapPoints) {
    if (PathMapPoints.Length == 0)
        return []

    ordered := [PathMapPoints[1]]
    remaining := []

    loop PathMapPoints.Length {
        if (A_Index > 1)
            remaining.Push(PathMapPoints[A_Index])
    }

    while (remaining.Length > 0) {
        last := ordered[-1]
        minDist := 999999, minIndex := -1

        for i, coord in remaining {
            dist := Sqrt((last.x - coord.x) ** 2 + (last.y - coord.y) ** 2)
            if (dist < minDist) {
                minDist := dist
                minIndex := i
            }
        }

        ordered.Push(remaining[minIndex])

        remaining.RemoveAt(minIndex)
    }

    return ordered
}

CannotPlaceUnits() {
    global CannotPlaceUnitsArr
    for index, placementAmount in CannotPlaceUnitsArr {
        if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, placementAmount)) {
            return true
        }
    }
    return false
}

HasNotEnoughMoney() {
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0.8, NotEnoughMoney)) {
        return true
    }
    return false
}

InfiniteBuff(slotNum) {
    global SPACurse, SPABG, CurseInput
    filteredUnits := []
    for index, unit in successfulCoordinates {
        if (unit.slot == "slot_" slotNum) {
            filteredUnits.Push(unit)
        }
    }

    try {
        if CurseInput.Has(slotNum) && Number(CurseInput.Get(slotNum).Text) {
            loop filteredUnits.Length {
                if (A_Index == 2 || A_Index == 4) {
                    Sleep ((0.6 * (CurseInput.Get(slotNum).Text) - 1.3) * 1000) + 2000
                } else if (A_Index == 3) {
                    Sleep ((30 - 0.6 * 7.1 - 1.1) * 1000)  ; Before 3rd unit
                }

                unit := filteredUnits[A_Index]

                BetterClick(328, 186)

                Sleep(50)

                BetterClick(unit.x, unit.y)

                Sleep(50)

                BetterClick(373, 237)
            }
        } else {
            loop filteredUnits.Length {
                if (A_Index == 2 || A_Index == 4) {
                    Sleep ((0.6 * (7.1) - 1.3) * 1000) + 2000
                } else if (A_Index == 3) {
                    Sleep ((30 - 0.6 * 7.1 - 1.1) * 1000)  ; Before 3rd unit
                }

                unit := filteredUnits[A_Index]

                BetterClick(328, 186)

                Sleep(50)

                BetterClick(unit.x, unit.y)

                Sleep(50)

                BetterClick(373, 237)
            }
        }
    } catch {
        loop filteredUnits.Length {
            if (A_Index == 2 || A_Index == 4) {
                Sleep ((0.6 * (7.1) - 1.3) * 1000) + 2000
            } else if (A_Index == 3) {
                Sleep ((30 - 0.6 * 7.1 - 1.1) * 1000)  ; Before 3rd unit
            }

            unit := filteredUnits[A_Index]

            BetterClick(328, 186)

            Sleep(50)

            BetterClick(unit.x, unit.y)

            Sleep(50)

            BetterClick(373, 237)
        }
    }
}

SpiralPlacement(gridPlacement := false) {
    global startX, startY, endX, endY, step, successfulCoordinates, maxedCoordinates
    successfulCoordinates := [] ; Reset successfulCoordinates for each run
    maxedCoordinates := []
    savedPlacements := Map()

    centerX := GetWindowCenter(RobloxWindow).x
    centerY := GetWindowCenter(RobloxWindow).y
    radius := step
    direction := [[1, 0], [0, 1], [-1, 0], [0, -1]]
    dirIndex := 0
    directionCount := 0

    ; Iterate through all slots (1 to 6)
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := UnitEnabled.Get(slotNum)
        placements := placementFM.Get(slotNum)
        unitType := TypeFM.Get(slotNum)
        upgrades := UpgFM.Get(slotNum)

        ; Skip if the slot is not enabled
        if !(enabled = 1) {
            continue
        }

        AddToLog("Starting placements for Slot " slotNum " with " placements " placements.")

        placementCount := 0
        currentX := centerX - deltaX
        currentY := centerY - deltaY
        steps := 30
        maxSteps := 5

        while (placementCount < placements) {
            for index, stepSize in [steps] {

                if PlaceUnit(currentX, currentY, slotNum) {
                    placementCount++
                    successfulCoordinates.Push({ x: currentX, y: currentY, slot: "slot_" slotNum }) ; Track successful placements
                    try {
                        if savedPlacements.Get("slot_" slotNum) {
                            savedPlacements.Set("slot_" slotNum, savedPlacements.Get("slot_" slotNum) + 1)
                        }
                    } catch {
                        savedPlacements.Set("slot_" slotNum, 1)
                    }

                    if placementCount >= placements {
                        break
                    }

                    if (gridPlacement) {
                        PlaceInGrid(currentX, currentY, slotNum, &placementCount, &successfulCoordinates, &
                            savedPlacements, &placements)
                    }

                }

                if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
                {
                    BetterClick(373, 237)
                }

                isMatchFinished() ; next
                BetterClick(565, 563) ; move mouse
                if ShouldStopUpgrading(1) {
                    AddToLog("Stopping due to finding lobby  condition.")
                    return isMatchFinished()
                }
                DisconnectCheck()

                currentX += direction[dirIndex + 1][1] * steps
                currentY += direction[dirIndex + 1][2] * steps

                currentX += Random(-15, 15)
                currentY += Random(-15, 15)

                if isInsideRect(rect1, currentX, currentY) or isInsideRect(rect2, currentX, currentY) or isInsideRect(
                    rect3, currentX, currentY) {
                    steps := 30
                    currentX := centerX - deltaX
                    currentY := centerY - deltaY
                }

                if currentX > 780 or currentY > 580 or currentX <= 0 or currentY < 0 {
                    steps := 30
                    currentX := centerX - deltaX
                    currentY := centerY - deltaY
                }
            }

            directionCount++

            if directionCount == 2 {
                steps += 30
                directionCount := 0
            }

            dirIndex := Mod(dirIndex + 1, 4)
            if ShouldStopUpgrading(1) {
                AddToLog("Stopping due to lobby condition.")
                return isMatchFinished()
            }
        }

        AddToLog("Completed " placementCount " placements for Slot " slotNum ".")
    }

    UpgradeUnits()

    AddToLog("All slot placements and upgrades completed.")
    while gameEnded == false {
        BetterClick(328, 186)
        isMatchFinished()
        ShouldStopUpgrading()
        Sleep(500)
    }
}

PlaceInGrid(startX, startY, slotNum, &placementCount, &successfulCoordinates, &savedPlacements, &placements) {
    ; Places untis in a 2x2 grid, starting from the top left where the initial unit is placed (as dictated by startX and startY)
    ; U x
    ; x x
    ;"Y"     ;"X"
    ;[number1,number2]

    gridOffsets := [
        [30, 0],  ; Row 1, Column 0
        [0, 30],  ; Row 0, Column 1
        [30, 30]   ; Row 1, Column 1]
    ]
    for index, offset in gridOffsets {

        ; Adds the value that's stored in the array at the current index to either x or y's starting location
        gridX := startX + offset[2] ; Move horizontally by 'step' from the initial start location
        gridY := startY + offset[1] ; Move vertically by 'step' from the initial start location

        if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
        {
            BetterClick(373, 237)
        }

        isMatchFinished() ; next
        BetterClick(565, 563) ; move mouse
        if ShouldStopUpgrading(1) {
            AddToLog("Stopping due to finding lobby condition.")
            return isMatchFinished()
        }
        DisconnectCheck()

        if PlaceUnit(gridX, gridY, slotNum) {
            placementCount++ ; Increment the placement count
            successfulCoordinates.Push({ x: gridX, y: gridY, slot: "slot_" slotNum }) ; Track the placement
            AddToLog("Placed unit at (" gridX ", " gridY ") in 3x3 grid.")

            ; Update or initialize saved placements for the current slot
            try {
                if savedPlacements.Get("slot_" slotNum) {
                    savedPlacements.Set("slot_" slotNum, savedPlacements.Get("slot_" slotNum) + 1)
                }
            } catch {
                savedPlacements.Set("slot_" slotNum, 1)
            }

            ; Check if placement limit is reached
            if placementCount >= placements {
                break
            }

        }

    } ; End for

}

TryPlacingUnits(map) {
    switch PLDDL.Text {
        case "Spiral":
            SpiralPlacement(false)
        case "Manual":
            ;ManualPlacement()
        default:
            Placement(map)
    }
}

IsMaxed(coord) {
    global maxedCoordinates
    for _, maxedCoord in maxedCoordinates {
        if (maxedCoord.x = coord.x && maxedCoord.y = coord.y) {
            return true
        }
    }
    return false
}

global successfulCoordinates := []

UpgradeUnits() {
    if UpgradePriorityE == 1 {
        global successfulCoordinates, maxedCoordinates, unitUpgradePrioritydropDowns, gameEnded, UpgFM
        AddToLog("Beginning prioritized unit upgrades.")

        slotPriorityMap := Map()
        for index, dropDown in unitUpgradePrioritydropDowns {
            priorityText := dropDown.Text
            if priorityText && priorityText != "" {
                slotPriorityMap["slot_" index] := priorityText
            }
        }
        SortByPriority(&successfulCoordinates, slotPriorityMap)

        for coord in successfulCoordinates {
            upgradeSlot := UpgFM.Get(Number(StrReplace(coord.slot, "slot_")))
            while !IsMaxUpgrade(upgradeSlot) {
                if (gameEnded == true) {
                    break 2
                }

                if ShouldStopUpgrading() {
                    AddToLog("Found return to lobby, going back.")
                    successfulCoordinates := []
                    maxedCoordinates := []
                    return isMatchFinished()
                }

                if UpgradeUnit(coord.x, coord.y, coord.slot) {
                    break
                }

                if ShouldStopUpgrading() {
                    AddToLog("Found return to lobby, going back.")
                    successfulCoordinates := []
                    maxedCoordinates := []
                    return isMatchFinished()
                }

                Sleep(200)

                if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) {
                    BetterClick(373, 237)
                }

                isMatchFinished() ; next
                BetterClick(565, 563) ; move mouse
                DisconnectCheck()
            }

            if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
            {
                BetterClick(373, 237)
            }

            BetterClick(565, 563) ; move mouse
            AddToLog("Max upgrade reached for: X" Floor(coord.x) " Y" Floor(coord.y) ". Moving onto next unit")
            maxedCoordinates.Push(coord)
        }

        AddToLog("All units upgraded or maxed.")
        while !ShouldStopUpgrading() {
            isMatchFinished() ; next
        }

        return isMatchFinished()
    }
    else {
        global successfulCoordinates
        global maxedCoordinates
        global gameEnded

        AddToLog("Beginning unit upgrades.")

        while true { ; Infinite loop to ensure continuous checking
            for index, coord in successfulCoordinates {
                if (gameEnded == true) {
                    break 2
                }

                upgradeSlot := UpgFM.Get(StrReplace(coord.slot, "slot_"))
                if ShouldStopUpgrading() {
                    AddToLog("Found return to lobby, going back.")
                    successfulCoordinates := []
                    maxedCoordinates := []
                    return isMatchFinished()
                }

                if UpgradeUnit(coord.x, coord.y, coord.slot) {
                    AddToLog("Max upgrade reached for: X" Floor(coord.x) " Y" Floor(coord.y))
                    maxedCoordinates.Push(successfulCoordinates.Get(index))
                    successfulCoordinates.RemoveAt(index) ; Remove the coordinate
                    continue ; Skip to the next coordinate
                }

                Sleep(200)
                if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
                {
                    BetterClick(373, 237)
                }

                isMatchFinished() ; next
                BetterClick(565, 563) ; move mouse
                DisconnectCheck()
            }

            ; If all units are maxed, still check for stopping condition
            if successfulCoordinates.Length == 0 and maxedCoordinates.Length > 0 {
                DisconnectCheck()
                isMatchFinished() ; next
                if ShouldStopUpgrading() {
                    AddToLog("Stopping due to finding return to lobby button.")
                    return isMatchFinished()
                }
                Sleep(2000) ; Prevent excessive looping

            }

            isMatchFinished()
            DisconnectCheck()
        }
    }
}

DisplayObj(Obj, Depth := 5, IndentLevel := "") {
    if Type(Obj) = "Object"
        Obj := Obj.OwnProps()
    for k, v in Obj {
        List .= IndentLevel "[" k "]"
        if (IsObject(v) && Depth > 1)
            List .= "`n" DisplayObj(v, Depth - 1, IndentLevel . "    ")
        else
            List .= " => " v
        List .= "`n"
    }
    return RTrim(List)
}

SortByPriority(&successful, slotPriorityMap) {
    for i, item in successful {
        j := i
        currentPriority := slotPriorityMap[item.slot]

        while (j > 1) {
            prevItem := successful[j - 1]
            prevPriority := slotPriorityMap[prevItem.slot]

            if (prevPriority > currentPriority) {
                successful[j] := prevItem
                successful[j - 1] := item
            } else {
                break
            }
            j := j - 1
        }
    }
}

SuccessfulToString(arr) {
    output := ""
    for index, item in arr {
        output .= "Slot: " item.slot ", X: " item.x ", Y: " item.y "`n"
    }
    return output
}

UpgradeUnit(x, y, slot) {
    global gameEnded

    if gameEnded == true {
        return true
    }
    BetterClick(x, y)
    sleep 100
    if (IsMaxUpgrade(UpgFM.Get(Number(StrReplace(slot, "slot_"))))) {
        return true
    }
    SendInput("r")
    if (IsMaxUpgrade(UpgFM.Get(Number(StrReplace(slot, "slot_"))))) {
        return true
    }
    SendInput("r")
    if (IsMaxUpgrade(UpgFM.Get(Number(StrReplace(slot, "slot_"))))) {
        return true
    }
    SendInput("r")
    if (IsMaxUpgrade(UpgFM.Get(Number(StrReplace(slot, "slot_"))))) {
        return true
    }
    Sleep 1000
    BetterClick(785, 550)
}

IsMaxUpgrade(upgrade) {
    Sleep 500
    ;if (ok := FindText(&X, &Y, 142, 346, 406, 472, 0, 0, MaxUpgrade) or (ok := FindText(&X, &Y, 142, 346, 406, 472, 0, 0, MaxUpgrade2)) or (ok := FindText(&X, &Y, 142, 346, 406, 472, 0, 0, MaxUpgrade3))) {
    ;return true
    ;}
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, UpgradesMap.Get("UPG" . upgrade))) {
        return true
    }
}

UpgradesMap := Map(
    "UPG1",
    "|<Upgrade 0>*90$25.zzzzzzzzzzzzzzzzzzzzzVsQ7ks63ts1lwwMsySQQTCCCDb777nXXXtsllww0syT0wTDkyDbzz7kzz3sTz1yDzlzzzzzzzzz",
    "UPG2", "|<Upgrade 1>*89$22.zzzzzzzzzzzsTMDVkUyS3XtkCDb0sySXXtyCDbssyTXXtyCDbssyTXXtzyDVzky7y3wTwTzzzzzzzU",
    "UPG3",
    "|<Upgrade 2>*90$25.zzzzzzzzzzzzz3ksDVUA7nk3XtkllwsssySQQTDsSDbsD7nkTXts1lws0syS0QTDzyDVzy7kzy3wTzXzzzzzzzzw",
    "UPG4",
    "|<Upgrade 3>*90$25.zzzzzzzzzzzzz3ksDVkA7nk3XtsllwzUsyTkwTDsCDbz77nXXXts1lww0syT1wTDzyDVzy7kzy3wTzXzzzzzzzzw",
    "UPG5", "|<Upgrade 4>*88$24.zzzzzzzzzzzzsQm3sME3tslXtslXtslXtslXtk1Xtk1Xts1XtzlXtzlXtzlXtzzXsTz3sTy3wTz7zzzzzzzzU",
    "UPG6", "|<Upgrade 5>*90$23.zzzzzzzzzzzz3UUy601ww1Xtsz7nkSDbUQTC0MySMlwzlXts37nUCDbkwTDzsy7zVwDy3wTyDzzzzzzzw",
    "UPG7", "|<Upgrade 6>*89$24.zzzzzzzzzzzzsTW3sS23tw3XtsTXtszXts7Xtk3Xtk3XtllXtsXXts3Xtw7XtzzXsTz3sTy3wTz7zzzzzzzzU",
    "UPG8", "|<Upgrade 7>*89$24.zzzzzzzzzzzzsM23sE03tk1XtzXXtz3Xtz7Xty7XtyDXtwTXtwTXtwTXtwTXtzzXsTz3sTy3wTz7zzzzzzzzU",
    "UPG9", "|<Upgrade 8>*92$24.zzzzzzzzzzzzsS63sM23ts3XtslXts3Xts3Xts3XtslXtllXts1Xts3Xtw7XtzzXsTz3sTy3wzz7zzzzzzzzU",
    "UPG10", "|<Upgrade 9>*90$24.zzzzzzzzzzzzsQC3sM23ts3XtlnXtkVXts1Xtw3XtzXXtz3Xts7XtsDXtsTXtzzXsTz3sTy3wTz7zzzzzzzzU",
    "UPG11",
    "|<Upgrade 10>*92$32.zzzzzzzzzzzzzzzzsTT3Uy73UMDbUk3XtkAMsyQ3CCDbsXXXty8ssyTWCCDbslXXtyA0syTXUSDbswDXtzzzsy7zzwDVzzy3wzzzlzzzzzzzzzzzU",
    "UPG12",
    "|<Upgrade 11>*90$29.zzzzzzzzzzzzzzz3vxUy73V1ww63Xtk877nUECDbcoQTDlssyTXllwz7XXtyD77nwSCDbswQTDzzsy7zzVwDzy3wTzyDzzzzzzzzzw",
    "UPG13",
    "|<Upgrade 12>*91$32.zzzzzzzzzzzzzzzzsTT3Uy730MDbUk3Xtk8MsyQ2CCDbcnXXtyDVsyTXkSDbskTXtyA0syTW0CDbsk3Xtzzzsy7zzwDVzzy3wzzzlzzzzzzzzzzzU",
    "UPG14",
    "|<Upgrade MAX>*88$29.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzztzzzzUTXly8S7XwsMC3tkEQ7nU0lD78FWCCNW0SQz40Qty1wtnwntnzzzzlzzzznzzzzzzzzzzzzzzzzzz7zzzz"
)

ShouldStopUpgrading(sleepamount := 300) {
    Sleep sleepamount
    if CheckForLobbyButton() {
        Sleep(100)
        return DetermineOutcome()
    }
}

LookDown() {
    MouseMove(400, 300)
    loop 20 {
        SendInput("{WheelUp}")
        Sleep 50
    }
    Sleep 200
    MouseGetPos(&x, &y)
    MouseMove(400, 300)
    SendInput(Format("{Click {} {} Left}", x, y + 150))

    loop 20 {
        SendInput("{WheelDown}")
        Sleep 50
    }
}

LoadedLoop(map, Timeout := false) {
    global hasReconnect, gameEnded
    AddToLog("Waiting to load in")
    if Timeout {
        loadingtimeout := A_TickCount
    }
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            global StageStartTime := A_TickCount
            AddToLog("Loaded in")
            gameEnded := false
            if (hasReconnect == 1) {
                if (WebhookE ? (DCWebhookE ? true : false) : false)
                    discord.SendEmbed("Reconnect")
                hasReconnect := 0
            }
            Sleep 1000
            OnSpawnSetup(map)
            break
        }
        else if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, P)) {
            Sleep 10000
            if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, P) and (ok !=
                FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart))) {
                global StageStartTime := A_TickCount
                AddToLog("Loaded in late")
                gameEnded := false
                if (hasReconnect == 1) {
                    if (WebhookE ? (DCWebhookE ? true : false) : false)
                        discord.SendEmbed("Reconnect")
                    hasReconnect := 0
                }
                Sleep 1000
                OnSpawnSetup(map)
                break
            }
        }
        if Timeout {
            if (A_TickCount - loadingtimeout) >= 120000 {
                AddToLog("Loading timed out")
                return false
            }
        }
        DisconnectCheck()
    }
}

StartedLoop(map) {
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            continue
        }
        AddToLog("Game started")
        TryPlacingUnits(map)
        break
    }
}

LobbyLoop() {
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 746, 476, 862, 569, 0, 0, AreasText)) {
            break
        }
        DisconnectCheck()
    }
    AddToLog("Returned to lobby, going back to raids")
    return GoToRaids()
}

CheckForLobbyButton() {
    if (ok := FindText(&X, &Y, 273, 103, 482, 214, 0, 0, LobbyText)) {
        return true
    }
}

CheckIngameSettings() {
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, DisableAutoUpgradeUI)) {
        BetterClick(526, 263)
        Sleep(300)
    }
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, ShowUpgradeUIOnLeft)) {
        BetterClick(526, 312)
        Sleep(300)
    }

    return true
}

TPtoSpawn() {
    CoordMode("Mouse", "Client")
    BetterClick(27, 574) ; setings
    Sleep 1000
    BetterClick(400, 287)
    Sleep 600
    loop 4 {
        Sleep 150
        SendInput("{WheelDown 1}") ; scroll
    }
    Sleep 600
    CheckIngameSettings()
    Sleep(500)
    BetterClick(525, 366) ; tp to spawn
    Sleep 600
    BetterClick(582, 175) ; exit settings

}

DetectWave() {
    static previousWave := "" 

    ocrResult := OCR.FromRect(160 + deltaX, 100 + deltaY, (260 - 160), (125 - 100), , 2)

    if ocrResult {
        currentWaveText := StrReplace(ocrResult.text, "Wave ", "")
        currentWaveText := RegExReplace(currentWaveText, "[^0-9]")

        if currentWaveText {
            currentWave := currentWaveText + 0

            AddToLog("OCR-detected wave: " currentWave)

            if (currentWave <= 14) {
                totalGems := 3 * currentWave
            } else {
                totalGems := 3 * 14 + 5 * (currentWave - 14)
            }

            AddToLog("Total gems: " totalGems)

            previousWave := currentWave
            return currentWave
        } else {
            AddToLog("OCR failed. Using Findtext instead")

            for i, wave in Waves {
                startTime := A_TickCount
                if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, wave)) {
                    endTime := A_TickCount
                    timeTaken := (endTime - startTime) / 1000

                    if (i <= 14) {
                        totalGems := 3 * i
                    } else {
                        totalGems := 3 * 14 + 5 * (i - 14)
                    }

                    AddToLog("FindText-detected wave: " i ". Time taken: " timeTaken " seconds. Total gems: " totalGems)

                    previousWave := wave
                    return i ; Current wave
                }
            }
        }
    } else {
        AddToLog("OCR failed. Using Findtext instead")

        for i, wave in Waves {
            startTime := A_TickCount
            if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, wave)) {
                endTime := A_TickCount
                timeTaken := (endTime - startTime) / 1000

                if (wave <= 14) {
                    totalGems := 3 * wave
                } else {
                    totalGems := 3 * 14 + 5 * (wave - 14)
                }

                AddToLog("FindText-detected wave: " wave ". Time taken: " timeTaken " seconds. Total gems: " totalGems)

                previousWave := wave
                return i ; Current Wave
            }
        }
    }
}

AntiCaptcha() {
    global deltaX, deltaY
    ocrResult := OCR.FromRect(230 + deltaX, 290 + deltaY, (570 - 230), (340 - 290), , 2)
    ; Display OCR results
    DisconnectCheck()
    if ocrResult {
        BetterClick(414, 342)
        AddToLog("Captcha Detected: " ocrResult.Text)

        ; Clean up the captcha string
        captcha := StrReplace(ocrResult.Text, " ")  ; Remove spaces
        if (StrLen(captcha) <= 1 || RegExMatch(captcha, "[A-Za-z]")) {
            AddToLog("invalid captcha retrying")
            BetterClick(584, 192) ; close captcha
            return
        }

        ; Remove special characters like /, -, and .
        captcha := RegExReplace(captcha, "[^0-9]")

        ; Send captcha
        Send(captcha)
    } else {
        AddToLog("NO CAPTCHA FOUND.")
    }

    BetterClick(309, 386) ; select
    Sleep 1500
    BetterClick(383, 221)
    Sleep 500

    sleep 6000
    if (ok := FindText(&X, &Y, 10, 70, 350, 205, 0, 0, LoadingScreen)) {
        return
    }
    if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
        return
    }
    AddToLog("Walking to ensure the UI pops up again if it didnt matchmake")

    loop 2 {
        HoldKey("D", 400)
        HoldKey("A", 800)
        HoldKey("Space", 2000)
    }

    Sleep 1500
    if (ok := FindText(&X, &Y, 221, 206, 403, 355, 0, 0, MatchmakeUI)) {
        AddToLog("Waiting for captcha cooldown then retrying")
        Sleep 6000
    }
    DisconnectCheck()
    return
}

TapToMove(toggle) {

    SendInput("{Esc}")
    Sleep 1000
    BetterClick(246, 101)
    Sleep 300
    SendInput("{Down}")
    Sleep 100
    SendInput("{Down}")
    Sleep 300
    if (toggle) {
        SendInput("{Right}")
        Sleep 300
        SendInput("{Right}")
    }
    else {
        SendInput("{Left}")
        Sleep 300
        SendInput("{Left}")
    }
    Sleep 300
    SendInput("{Esc}")
    Sleep 1000
}

PixelSearchFunction(Color, Xtl, Ytl, Xbr, Ybr, Tol) {
    CoordMode("Pixel", "Window")
    if (!WinActive("ahk_exe RobloxPlayerBeta.exe")) {
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
    }
    global foundX, foundY
    if (PixelSearch(&foundX, &foundY, Xtl, Ytl, Xbr, Ybr, Color, Tol)) {
        CoordMode("Mouse", "Window")
        return true
    } else {
        CoordMode("Mouse", "Window")
        return false
    }
}

MouseRelativeMove() {
    MouseMove(1, 1, 5, "R")
    Sleep(100)
    MouseMove(-1, -1, 5, "R")
}

global startMoveTime := A_TickCount

MoveTowards(key) {
    global startMoveTime
    if (A_TickCount - startMoveTime >= 5000) {
        Send("{" key " Up}")
        SetTimer(, 0)
        return
    }
    Send("{" key " Down}")

    Send("{Space}")

    Sleep(100)
}


MoveTowardsD() {
    MoveTowards("d")
    return
}

MoveTowardsA() {
    MoveTowards("a")
    return
}

MoveTowardsS() {
    MoveTowards("s")
    return
}

MoveTowardsW() {
    MoveTowards("w")
    return
}

IsColorInRange(color, targetColor, tolerance := 50) {
    ; Extract RGB components
    r1 := (color >> 16) & 0xFF
    g1 := (color >> 8) & 0xFF
    b1 := color & 0xFF

    ; Extract target RGB components
    r2 := (targetColor >> 16) & 0xFF
    g2 := (targetColor >> 8) & 0xFF
    b2 := targetColor & 0xFF

    ; Check if within tolerance range
    return Abs(r1 - r2) <= tolerance
    && Abs(g1 - g2) <= tolerance
    && Abs(b1 - b2) <= tolerance
}

OnSpawnSetup(map) {
    SendInput ("{Tab}")
    LookDown()
    Sleep 200
    TapToMove(true)

    switch map {
        case "Planet Greenie":
            MoveForGreenie()
        case "Snowy Town":
            MoveForSnowyTown()
        case "Ant Kingdom":
            MoveForAntKingdom()
        case "Magic Town":
            MoveForMagicTown()
        case "Magic Hill":
            MoveForMagicHill()
        case "Navy Bay":
            MoveForNavyBay()
        case "Fiend City":
            MoveForFiendCity()
        case "Spirit World":
            MoveForSpiritWorld()
        case "Haunted Academy":
            MoveForHauntedAcademy()
        case "Space Center":
            MoveForSpaceCenter()
        case "Mountain Temple":
            MoveForMountainTemple()
        case "Cursed Festival":
            MoveForCursedFestival()
        case "Nightmare Train":
            MoveForNightmareTrain()
        case "Air Craft":
            MoveForAirCraft()
        case "Hellish City":
            MoveForHellish()
        case "Shibuya District":
            MoveForShibuya()
        case "Spirit Town":
            MoveForSpiritTown()
        case "Ruined City":
            MoveForRuinedCity()
        case "Sand Village":
            MoveForSandVillage()
        case "Alien Spaceship":
            MoveForAlienSpaceship()
        case "Fabled Kingdom":
            MoveForFabledKingdom()
        case "Puppet Island":
            MoveForPuppetIsland()
        case "Future City":
            MoveForFutureCity()
        case "Storm Hideout":
            MoveForStormHideout()
        case "Spirit Invasion":
            MoveForSpiritInvasion()
    }

    Sleep(200)
    TapToMove(false)
    Sleep(1000)
    BetterClick(350, 103) ; click yes
    BetterClick(350, 100) ; click yes
    BetterClick(350, 97) ; click yes
    Sleep(200)
    StartedLoop(map)
}

IsPSLinkValid(url) {
    if url
        RegExMatch(url,
            "i)((http(s)?):\/\/)?((www|web)\.)?roblox\.com\/([a-z]{2}\/)?games\/8304191830\/?([^\/]*)\?privateServerLinkCode=.{32}(\&[^\/]*)*", &
            NewPrivServer)
    if ((StrLen(url) > 0) && !IsObject(NewPrivServer)) {
        if InStr(url, "/share?code") {
            MsgBox("
                    (
                    You entered a 'share?code' link!
                    To fix this:
                        1. Paste this link into your browser
                        2. Wait for Anime Adventures to load
                        3. Copy the link at the top of your browser.
                    )"
                , "Unresolved Private Server Link")
            return false
        } else {
            MsgBox("Make sure your link is:`r`n- copied correctly and completely`r`n- for Anime Adventures",
                "Invalid Private Server Link")
            return false
        }
    }
    return true
}

testReconnect(*) {
    if IsPSLinkValid(PServerURL)
        CloseRoblox()
    if (DisconnectCheck(1) = 1)
        MsgBox "Success!", "Reconnect Test", 0x1000
}

ObjMinIndex(obj) {
    for k, v in obj
        return k
    return 0
}

DisconnectCheck(testCheck := 0) {
    global gameEnded, disconnectionsSession, disconnectionsSessionText

    ; Check if roblox is disconnected
    ActivateRoblox()
    GetRobloxClientPos()
    if ((windowWidth > 0) && !WinExist("Roblox Crash") && !FindText(&X, &Y, 0, 0, 800, 600, 0, 0, RobuxImage)) {
        pBMScreen := Gdip_BitmapFromScreen(windowX + windowWidth // 2 "|" windowY + windowHeight // 2 "|200|80")
        if (Gdip_ImageSearch(pBMScreen, bitmaps["disconnected"], , , , , , 2) != 1) {
            Gdip_DisposeImage(pBMScreen)
            return 0
        }
        Gdip_DisposeImage(pBMScreen)
    }

    ; Obtain Link Code
    linkCodes := Map()
    for k, v in ["PServerURL"] {
        if (%v% && (StrLen(%v%) > 0)) {
            if RegexMatch(%v%, "i)(?<=privateServerLinkCode=)(.{32})", &linkCode)
                linkCodes[k] := linkCode[0]
            else
                AddToLog("Error`nPrivate Server Invalid")
        }
    }

    ; Stop upgrades / placements
    gameEnded := true

    disconnectionsSession++
    disconnectionsSessionText := disconnectionsSession

    if !testCheck
        if (WebhookE ? (DCWebhookE ? true : false) : false)
            discord.SendEmbed("Disconnect")

    loop {
        server := ((A_Index <= 20) && (n := ObjMinIndex(linkcodes))) ? n : 0

        i := A_Index, success := 0
        loop 5 {
            switch Mod(i, 5) {
                case 1, 2:
                    ;Close Roblox
                    CloseRoblox()
                    ;Run Server Deeplink
                    AddToLog("Attempting Private Server")
                    try Run '"roblox://placeID=8304191830' (server ? ("&linkCode=" linkCodes[server]) : "") '"'

                case 3, 4:
                    ;Run Server Deeplink (without closing)
                    AddToLog("Attempting Private Server Without Closing")
                    try Run '"roblox://placeID=8304191830' (server ? ("&linkCode=" linkCodes[server]) : "") '"'

                default:
                    if server {
                        CloseRoblox()
                        ;Run Server Link (legacy method w/ browser)
                        AddToLog("Attempting Private Server (Browser)")
                        try {
                            run PServerURL
                        } catch {
                            continue 2
                        }
                    } else {
                        (i = 1) && CloseRoblox()
                        try Run '"roblox://placeID=8304191830"'
                    }
            }

            ;STAGE 1 - wait for Roblox window
            loop 240 {
                if GetRobloxHWND() {
                    ActivateRoblox()
                    SetupMacro()
                    AddToLog("Roblox Detected")
                    break
                }
                if (A_Index = 240) {
                    AddToLog("Error`nNo Roblox Found`nRetry: " i)
                    break 2
                }
                Sleep 1000 ; timeout 4 mins, wait for any Roblox update to finish
            }
            ;STAGE 2 - wait for loaded game
            loop 180 {
                SetupMacro()
                ActivateRoblox()
                if !GetRobloxClientPos() {
                    AddToLog("Warning`nDisconnected during Reconnect")
                    continue 2
                }
                pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY + 30 "|" windowWidth "|" windowHeight - 30)
                if (ok := FindText(&X, &Y, 746, 476, 862, 569, 0, 0, AreasText)) {
                    AddToLog("Success`nGame Loaded")
                    success := 1
                    break 2
                }
                if (Gdip_ImageSearch(pBMScreen, bitmaps["disconnected"], , , , , , 2) = 1) {
                    Gdip_DisposeImage(pBMScreen)
                    AddToLog("Warning`nDisconnected during Reconnect")
                    continue 2
                }
                Gdip_DisposeImage(pBMScreen)
                if (A_Index = 180) {
                    AddToLog("Error`nAA Load Timeout`nRetry: " i)
                    break 2
                }
                Sleep 1000 ; timeout 3 mins, slow loading
            }
        }

        ;Successful Reconnect
        if (success = 1) {
            ActivateRoblox()
            ;GoToRaids()
            AddToLog("Reconnect successful")
            if !testCheck
                if (WebhookE ? (DCWebhookE ? true : false) : false)
                    discord.SendEmbed("Reconnect")

            if testCheck = 1 {
                return 1
            }

            return GoToRaids()
        }
    }
}

CloseRoblox() {
    SC_L := "sc026" ; l
    SC_Esc := "sc001" ; Esc
    SC_Enter := "sc01c" ; Enter
    ; if roblox exists, activate it and send Esc+L+Enter
    if (hwnd := GetRobloxHWND()) {
        GetRobloxClientPos(hwnd)
        if (windowHeight >= 500) ; requirement for L to activate "Leave"
        {
            ActivateRoblox()
            prevKeyDelay := A_KeyDelay
            SetKeyDelay 250
            send "{" SC_Esc "}{" SC_L "}{" SC_Enter "}"
            SetKeyDelay prevKeyDelay
        }
        try WinClose "Roblox"
        Sleep 500
        try WinClose "Roblox"
        Sleep 4500 ;Delay to prevent Roblox Error Code 264
    }
    ; kill any remnant processes
    for p in ComObjGet("winmgmts:").ExecQuery(
        "SELECT * FROM Win32_Process WHERE Name LIKE '%Roblox%' OR CommandLine LIKE '%ROBLOXCORPORATION%'")
        ProcessClose p.ProcessID
}

HoldKey(key, duration) {
    SendInput ("{" key "up}")
    ; go to teleporter
    Sleep 100
    SendInput ("{" key " down}")
    Sleep duration
    SendInput ("{" key " up}")
    KeyWait key ; Wait for "d" to be fully processed
}

DetermineOutcome() {
    global winsSession, lossesSession, attemptsSession, attemptsSessionText, lossesSessionText, winsSessionText, gameEnded

    gameEnded := true

    attemptsSession++
    attemptsSessionText := attemptsSession

    ; Checks for win or loss
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, DeathText)) {
        lossesSession++
        lossesSessionText := lossesSession
        win := false

        if (WebhookE ? (SOWebhookE ? true : false) : false) {
            SendInput ("{Tab}")
            Sleep 150
            discord.SendEmbed("Loss")
        }
    }
    else {
        winsSession++
        winsSessionText := winsSession
        win := true
    }

    BetterClick(348, 391) ; Clicks next

    if win {
        if (WebhookE ? (SOWebhookE ? true : false) : false) {
            SendInput ("{Tab}")
            Sleep 150
            discord.SendEmbed("Completed")
        }
    }

    loop 10 {
        BetterClick(348, 391)
        Sleep(300)
    }

    SavedMouseCoord := A_CoordModeMouse
    CoordMode("Mouse", "Window")

    BetterClick(500, 153) ; Clicks Replay
    sleep 500
    BetterClick(500, 150)
    sleep 500
    BetterClick(500, 147)

    CoordMode("Mouse", SavedMouseCoord)
    return AfterGame()

}

/*StoryEnd(win := true) {
    SavedMouseCoord := A_CoordModeMouse
    CoordMode("Mouse", "Window")

    if win {
        return HandleNextStory()
    } else {
        BetterClick(500, 153) ; Clicks Replay
        sleep 500
        BetterClick(500, 150)
        sleep 500
        BetterClick(500, 147)
    }

    CoordMode("Mouse", SavedMouseCoord)
    return AfterGame()
} */

LegendEnd() {
    SavedMouseCoord := A_CoordModeMouse
    CoordMode("Mouse", "Window")

    BetterClick(500, 153) ; Clicks Replay
    sleep 500
    BetterClick(500, 150)
    sleep 500
    BetterClick(500, 147)

    CoordMode("Mouse", SavedMouseCoord)
    return AfterGame()
}

DebugRect(x, y, w, h) {
    hDC := DllCall("GetDC", "Ptr", mainGui.Hwnd, "Ptr")
    DllCall("gdiplus.dll\GdipCreateFromHDC", "Ptr", hDC, "Ptr*", &pGraphics := 0)
    DllCall("Gdiplus.dll\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
    DllCall("Gdiplus.dll\GdipCreatePen1", "UInt", 0xFF0000FF, "Float", 2, "Int", 2, "Ptr*", &pPen := 0)

    DllCall("Gdiplus.dll\GdipDrawRectangle", "Ptr", pGraphics, "Ptr", pPen, "Float", x, "Float", y, "Float", w,
        "Float",
        h)

    sleep 3000

}

isMatchFinished() {
    global gameEnded
    DisconnectCheck()

    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, EndScreen)) { ; checks for end screen
        BetterClick(328, 186) ; closes unit upg menu
        DetermineOutcome()
    }
}