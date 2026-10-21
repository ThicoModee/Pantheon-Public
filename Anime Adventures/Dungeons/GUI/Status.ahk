#Requires AutoHotkey v2.0
#Include gui.ahk

StatusTab() {
    global ActivityLog, statView
    global runtimeTotal:= 0, winsTotal:= 0, lossesTotal:= 0, attemptsTotal:= 0, disconnectionsTotal:= 0
    global winsSession:= 0, lossesSession:= 0, attemptsSession:= 0, disconnectionsSession:= 0, runtimeSession:= "00 : 00 : 00"
    global WinsValue, LossesValue, AttemptsValue, DisconnectionsValue, RuntimeValue
    global TotalRuntime := 0, totalRuntimeWithSession := 0, RuntimeText := "00 : 00 : 00", RuntimeTextSession := "00 : 00 : 00"
    global winsSessionText := 0, lossesSessionText := 0, attemptsSessionText := 0, disconnectionsSessionText := 0

    try {
        StatLoad()
    }

    ; --- Activity Log ---
    ; - Box & Title -
    holder := MaingUI.AddButton("x820 y10 w205 h447 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)

    divider := MaingUI.AddButton("x833 y42 w180 h4 Disabled", "")
    CreateImageButton(divider, 0, ButtonStyles["divider"]*)

    MainGUI.AddText("x890 y20 0x200 h" SGH, "Activity Log")
    ActivityLog := MainGUI.Add("Text", "x838 y70 w170 h" SGH " Center", "")
    ;ActivityLog := MainGUI.AddEdit("x820 y57 w220 h400 Center ReadOnly VScroll", "")
    ;ActivityLog.SetRounded(7)

    ; --- Stats ---
    holder := MaingUI.AddButton("x820 y465 w205 h165 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)

    MainGUI.AddText("x823 y475 w197 Center", "Stats")

    StatTypeButton := MaingUI.AddButton("x963 y472 w55 h19 Center", statView)
    CreateImageButton(StatTypeButton, 0, ButtonStyles["default"]*)
    StatTypeButton.OnEvent("Click", (*) => updateStatType(StatTypeButton))
    StatTypeButton.Text := statView

    StatResetButton := MaingUI.AddButton("x827 y472 w55 h19 Center", "Reset")
    CreateImageButton(StatResetButton, 0, ButtonStyles["default"]*)
    StatResetButton.OnEvent("Click", (*) => ResetStats())

    divider := MaingUI.AddButton("x833 y496 w180 h4 Disabled", "")
    CreateImageButton(divider, 0, ButtonStyles["divider"]*)

    MainGUI.AddText("x830 y509 0x200 Left w193 h" SGH, "Runtime")
    RuntimeValue := MaingUI.AddButton("x926 y508 w92 h16 0x100 Disabled Center", RuntimeText)
    CreateImageButton(RuntimeValue, 0, ButtonStyles["fake_for_group"]*)

    MainGUI.AddText("x830 y533 0x200 Left w193 h" SGH, "Wins")
    WinsValue := MaingUI.AddButton("x926 y532 w92 h16 0x100 Disabled Center", winsTotal)
    CreateImageButton(WinsValue, 0, ButtonStyles["fake_for_group"]*)

    MainGUI.AddText("x830 y557 0x200 Left w193 h" SGH, "Losses")
    LossesValue := MaingUI.AddButton("x926 y556 w92 h16 0x100 Disabled Center", lossesTotal)
    CreateImageButton(LossesValue, 0, ButtonStyles["fake_for_group"]*)

    MainGUI.AddText("x830 y581 0x200 Left w193 h" SGH, "Attempts")
    AttemptsValue := MaingUI.AddButton("x926 y580 w92 h16 0x100 Disabled Center", attemptsTotal)
    CreateImageButton(AttemptsValue, 0, ButtonStyles["fake_for_group"]*)
    
    MainGUI.AddText("x830 y605 0x200 Left w193 h" SGH, "Disconnections")
    DisconnectionsValue := MaingUI.AddButton("x926 y604 w92 h16 0x100 Disabled Center", disconnectionsTotal)
    CreateImageButton(DisconnectionsValue, 0, ButtonStyles["fake_for_group"]*)
}

AddToLog(text) {
    Timestamp := "[" A_Hour ":" A_Min ":" A_Sec "] "
    ActivityLog.H := 380
    ActivityLog.Value := Timestamp text "`n" ActivityLog.Value
}

updateStatType(StatTypeButton) {
    global statView

    if (statView == "Total") {
        statView := "Session"
        updateStats("Session")
    } else {
        statView := "Total"
        updateStats("Total")
    }
    StatTypeButton.Text := statView
    CreateImageButton(StatTypeButton, 0, ButtonStyles["default"]*)
}

updateStats(type) {
    global runtimeTotal, winsTotal, lossesTotal, attemptsTotal, disconnectionsTotal
    global TotalWins, TotalLosses, TotalAttempts, TotalDisconnections
    global WinsValue, LossesValue, AttemptsValue, DisconnectionsValue, RuntimeValue
    
    try {
        runtimeTotal := calculateTotalRuntime(sessionTime)
        runtimeSession := CalculateElapsedTime(sessionTime)
    } catch {
        runtimeTotal := RuntimeText
        runtimeSession := RuntimeTextSession
    } 

    TotalWins := winsTotal + winsSession
    TotalLosses := lossesTotal + lossesSession
    TotalAttempts := attemptsTotal + attemptsSession
    TotalDisconnections := disconnectionsTotal + disconnectionsSession

    if type == "Total" {
        WinsValue.Text := TotalWins
        CreateImageButton(WinsValue, 0, ButtonStyles["fake_for_group"]*)

        LossesValue.Text := TotalLosses
        CreateImageButton(LossesValue, 0, ButtonStyles["fake_for_group"]*)

        AttemptsValue.Text := TotalAttempts
        CreateImageButton(AttemptsValue, 0, ButtonStyles["fake_for_group"]*)

        DisconnectionsValue.Text := TotalDisconnections
        CreateImageButton(DisconnectionsValue, 0, ButtonStyles["fake_for_group"]*)

        RuntimeValue.Text := runtimeTotal
        CreateImageButton(RuntimeValue, 0, ButtonStyles["fake_for_group"]*)

    } else {
        WinsValue.Text := winsSessionText
        CreateImageButton(WinsValue, 0, ButtonStyles["fake_for_group"]*)

        LossesValue.Text := lossesSessionText
        CreateImageButton(LossesValue, 0, ButtonStyles["fake_for_group"]*)

        AttemptsValue.Text := attemptsSessionText
        CreateImageButton(AttemptsValue, 0, ButtonStyles["fake_for_group"]*)

        DisconnectionsValue.Text := disconnectionsSessionText
        CreateImageButton(DisconnectionsValue, 0, ButtonStyles["fake_for_group"]*)

        RuntimeValue.Text := runtimeSession
        CreateImageButton(RuntimeValue, 0, ButtonStyles["fake_for_group"]*)
    }
}

ResetStats() {
    global winsTotal, lossesTotal, attemptsTotal, disconnectionsTotal, runtimeTotal
    winsTotal := 0
    lossesTotal := 0
    attemptsTotal := 0
    disconnectionsTotal := 0
    runtimeTotal := "00 : 00 : 00"
    updateStats("Total")
    StatSave()
}

UpdateStatsInRealTime() {
    updateStats(statView)
    StatSave()
}

StartStatsUpdate() {
    global winsSession := 0,
        lossesSession := 0,
        attemptsSession := 0,
        disconnectionsSession := 0
    SetTimer(UpdateStatsInRealTime, 1000)
}

StopStatsUpdate() {
    SetTimer(UpdateStatsInRealTime, 0)
}

CalculateElapsedTime(StartTime) {
    ElapsedTimeMs := A_TickCount - StartTime
    ElapsedTimeSec := Floor(ElapsedTimeMs / 1000)
    ElapsedHours := Floor(ElapsedTimeSec / 3600)
    ElapsedMinutes := Floor(Mod(ElapsedTimeSec, 3600) / 60)
    ElapsedSeconds := Mod(ElapsedTimeSec, 60)
    global RuntimeTextSession := Format("{:+02} : {:+02} : {:+02}", ElapsedHours, ElapsedMinutes, ElapsedSeconds)
    Return Format("{:+02} : {:+02} : {:+02}", ElapsedHours, ElapsedMinutes, ElapsedSeconds)
}

calculateTotalRuntime(StartTime) { 
    ;global TotalRuntime
    sessionRuntime := A_TickCount - StartTime
    global totalRuntimeWithSession := TotalRuntime + sessionRuntime
    ElapsedTimeSec := Floor(totalRuntimeWithSession / 1000)
    ElapsedHours := Floor(ElapsedTimeSec / 3600)
    ElapsedMinutes := Floor(Mod(ElapsedTimeSec, 3600) / 60)
    ElapsedSeconds := Mod(ElapsedTimeSec, 60)
    global RuntimeText := Format("{:+02} : {:+02} : {:+02}", ElapsedHours, ElapsedMinutes, ElapsedSeconds)
    Return Format("{:+02} : {:+02} : {:+02}", ElapsedHours, ElapsedMinutes, ElapsedSeconds)
}