#Requires AutoHotkey v2.0
#Include gui.ahk

MainTab() {
    global SCCheckbox, CardPCheckbox, RPCCheckbox, StatWCheckbox
    global CardPriority := Map()
    global cardBG := Map()
    global ChatInput, PServerInput
    global BindResizeButton, BindStartButton, BindStopButton, BindPauseButton
    global resizeInput, startInput, stopInput, pauseInput
    global CardList
    global MatchmakeMode, SelectedCards
    CardList := ["New path", "Range", "Attack", "Health", "Shield", "Regen", "Explosive death", "Cooldown", "Speed",
        "Yen"]

    for i, v in CardFM {
        SelectedCards.Push(StrLower(StrReplace(CardList[v], " ", "_")))
    }

    Maintab1()

    TabCtrl.UseTab("MainTab2")
    Maintab2()

    MainTab1() {
        MainGUI.AddText("x852 y18 Center w141 h16", "Page 1")

        ;PreviousButton := mainGui.AddButton("x820 y10 w32 h32", "<")
        ;PreviousButton.OnEvent("Click", (*) => TabCtrl.Choose("Main"))
        ;CreateImageButton(PreviousButton, 0, ButtonStyles["default"]*)

        NextButton := mainGui.AddButton("x993 y10 w32 h32", ">")
        NextButton.OnEvent("Click", (*) => TabCtrl.Choose("MainTab2"))
        CreateImageButton(NextButton, 0, ButtonStyles["default"]*)

        /*; --- Send Chat ---
        ; - Box & Title -
        holder := MaingUI.AddButton("x820 y62 w205 h110 0x100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        
        MainGUI.AddText("x824 y67 Center w197 h15", "Send Chat")
        
        ; - Send Chat System -
        SCCheckbox := MainGUI.AddCheckBox(" x830 y92 h" SGH " w" SGW)
        SCCheckbox.Value := SendChatE
        SCCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y92 Left w79 h15", " Enabled")
        
        MainGUI.AddText("x830 y117 Left w193 h15", "Message")
        inputholder := MainGUI.AddButton("x830 y137 w185 h25 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        ChatInput := MainGUI.AddEdit("x830 y137 w185 h25", "")
        ChatInput.Text := chatContents
        ChatInput.OnEvent('Change', (*) => GUISave())
        ChatInput.SetRounded(7) */

        ; --- Congfigs ---
        holder := MaingUI.AddButton("x820 y62 w205 h110 0x100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y67 Center w197 h15", "Configs")

        MainGUI.AddText("x830 y90 w125", "Config Name")
        inputholder := MainGUI.AddButton("x830 y108 w125 h25 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        ConfigInput := MainGUI.AddEdit("x830 y108 w125 h25", "")
        ConfigInput.SetRounded(5)

        UploadButton := mainGui.AddButton("x960 y108 w55 h25", "Upload")
        CreateImageButton(UploadButton, 0, ButtonStyles["default"]*)

        LoadButton := mainGui.AddButton("x873 y141 w100 h25", "Load Config")
        CreateImageButton(LoadButton, 0, ButtonStyles["default"]*)

        ; --- Card Picker ---
        holder := MaingUI.AddButton("x820 y188 w205 h230 0x100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y193 w197 Center", "Card Picker")

        CardPCheckbox := MainGUI.AddCheckBox("x830 y213 h" SGH " w" SGW)
        CardPCheckbox.Value := CardPriorityE
        CardPCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y213 w79", " Enabled")

        MainGUI.AddText("x822 y233 w201 Center", "Priorities")
        divider := MaingUI.AddButton("x833 y253 w180 h4 0x100 Disabled", "")
        CreateImageButton(divider, 0, ButtonStyles["divider"]*)

        MainGUI.AddText("x830 y268 w15", "1")
        cardBG.Set(1, mainGUI.AddButton(" x845 y263 Disabled w70 h25 Center", CardList[CardFM.Get(1)]))
        CreateImageButton(cardBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(1, mainGUI.AddDropDownList(" x845 y263 w70 +0x4000000", CardList))
        CardPriority.Get(1).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(1), CardList, cardBG.Get(1)))
        CardPriority.Get(1).Text := CardList[CardFM.Get(1)]

        MainGUI.AddText("x830 y298 w15", "2")
        cardBG.Set(2, mainGUI.AddButton(" x845 y293 Disabled w70 h25 Center", CardList[CardFM.Get(2)]))
        CreateImageButton(cardBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(2, mainGUI.AddDropDownList(" x845 y293 w70 +0x4000000", CardList))
        CardPriority.Get(2).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(2), CardList, cardBG.Get(2)))
        CardPriority.Get(2).Text := CardList[CardFM.Get(2)]

        MainGUI.AddText("x830 y328 w15", "3")
        cardBG.Set(3, mainGUI.AddButton(" x845 y323 Disabled w70 h25 Center", CardList[CardFM.Get(3)]))
        CreateImageButton(cardBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(3, mainGUI.AddDropDownList(" x845 y323 w70 +0x4000000", CardList))
        CardPriority.Get(3).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(3), CardList, cardBG.Get(3)))
        CardPriority.Get(3).Text := CardList[CardFM.Get(3)]

        MainGUI.AddText("x830 y358 w15", "4")
        cardBG.Set(4, mainGUI.AddButton(" x845 y353 Disabled w70 h25 Center", CardList[CardFM.Get(4)]))
        CreateImageButton(cardBG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(4, mainGUI.AddDropDownList(" x845 y353 w70 +0x4000000", CardList))
        CardPriority.Get(4).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(4), CardList, cardBG.Get(4)))
        CardPriority.Get(4).Text := CardList[CardFM.Get(4)]

        MainGUI.AddText("x830 y388 w15", "5")
        cardBG.Set(5, mainGUI.AddButton(" x845 y383 Disabled w70 h25 Center", CardList[CardFM.Get(5)]))
        CreateImageButton(cardBG.Get(5), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(5, mainGUI.AddDropDownList(" x845 y383 w70 +0x4000000", CardList))
        CardPriority.Get(5).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(5), CardList, cardBG.Get(5)))
        CardPriority.Get(5).Text := CardList[CardFM.Get(5)]

        MainGUI.AddText("x925 y268 w15", "6")
        cardBG.Set(6, mainGUI.AddButton(" x940 y263 Disabled w70 h25 Center", CardList[CardFM.Get(6)]))
        CreateImageButton(cardBG.Get(6), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(6, mainGUI.AddDropDownList(" x940 y263 w70 +0x4000000", CardList))
        CardPriority.Get(6).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(6), CardList, cardBG.Get(6)))
        CardPriority.Get(6).Text := CardList[CardFM.Get(6)]

        MainGUI.AddText("x925 y298 w15", "7")
        cardBG.Set(7, mainGUI.AddButton(" x940 y293 Disabled w70 h25 Center", CardList[CardFM.Get(7)]))
        CreateImageButton(cardBG.Get(7), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(7, mainGUI.AddDropDownList(" x940 y293 w70 +0x4000000", CardList))
        CardPriority.Get(7).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(7), CardList, cardBG.Get(7)))
        CardPriority.Get(7).Text := CardList[CardFM.Get(7)]

        MainGUI.AddText("x925 y328 w15", "8")
        cardBG.Set(8, mainGUI.AddButton(" x940 y323 Disabled w70 h25 Center", CardList[CardFM.Get(8)]))
        CreateImageButton(cardBG.Get(8), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(8, mainGUI.AddDropDownList(" x940 y323 w70 +0x4000000", CardList))
        CardPriority.Get(8).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(8), CardList, cardBG.Get(8)))
        CardPriority.Get(8).Text := CardList[CardFM.Get(8)]

        MainGUI.AddText("x925 y358 w15", "9")
        cardBG.Set(9, mainGUI.AddButton(" x940 y353 Disabled w70 h25 Center", CardList[CardFM.Get(9)]))
        CreateImageButton(cardBG.Get(9), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(9, mainGUI.AddDropDownList(" x940 y353 w70 +0x4000000", CardList))
        CardPriority.Get(9).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(9), CardList, cardBG.Get(9)))
        CardPriority.Get(9).Text := CardList[CardFM.Get(9)]

        MainGUI.AddText("x923 y388 w17", "10")
        cardBG.Set(10, mainGUI.AddButton(" x940 y383 Disabled w70 h25 Center", CardList[CardFM.Get(10)]))
        CreateImageButton(cardBG.Get(10), 0, ButtonStyles["fake_for_group"]*)
        CardPriority.Set(10, mainGUI.AddDropDownList(" x940 y383 w70 +0x4000000", CardList))
        CardPriority.Get(10).OnEvent("Change", (*) => CardListWorker(CardPriority.Get(10), CardList, cardBG.Get(10)))
        CardPriority.Get(10).Text := CardList[CardFM.Get(10)]

        ;--- Mode Settings ---
        holder := MaingUI.AddButton("x820 y426 w205 h53 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y431 w197 Center", "Mode")

        MatchmakeModeList := ["Matchmaking", "Solo"]

        ModeBG := mainGUI.AddButton("x830 y449 Disabled w185 h24 Center", MatchmakeModeList[ModeFM])
        CreateImageButton(ModeBG, 0, ButtonStyles["fake_for_group"]*)
        MatchmakeMode := mainGUI.AddDropDownList("x830 y449 w185 +0x4000000", MatchmakeModeList)
        MatchmakeMode.OnEvent("Change", (*) => DropDownListWorker(MatchmakeMode, MatchmakeModeList, ModeBG))
        MatchmakeMode.Text := MatchmakeModeList[ModeFM]

        ;--- Keybind Settings ---
        ; - Keybind Box & Heading -
        holder := MaingUI.AddButton("x820 y487 w205 h143 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y492 w197 Center", "Hotkey Settings")

        ; - Resize -
        MainGUI.AddText("x830 y517 w45", "Resize:")
        holder := MainGUI.AddButton("x875 y512 w112 h25 Disabled")
        CreateImageButton(holder, 0, ButtonStyles["fake_for_group"]*)
        resizeInput := MainGUI.AddEdit("Disabled x875 y512 w112 h25 Center", "")
        resizeInput.SetRounded(5)
        resizeInput.Value := BindToHotkey(resizeBind)
        ; - Resize Bind -
        BindResizeButton := MainGUI.AddButton("x992 y512 w25 h25", Chr(0xE104))
        BindResizeButton.OnEvent("Click", BindHotkeyButton)
        CreateImageButton(BindResizeButton, 0, ButtonStyles["fake_for_group"]*)

        ; - Start -
        MainGUI.AddText("x830 y546 w45", "Start:")
        holder := MainGUI.AddButton("x875 y541 w112 h25 Disabled")
        CreateImageButton(holder, 0, ButtonStyles["fake_for_group"]*)
        startInput := MainGUI.AddEdit("Disabled x875 y541 w112 h25 Center", "")
        startInput.SetRounded(5)
        startInput.Value := BindToHotkey(startBind)
        ; - Start Bind -
        BindStartButton := MainGUI.AddButton("x992 y541 w25 h25", Chr(0xE104))
        BindStartButton.OnEvent("Click", BindHotkeyButton)
        CreateImageButton(BindStartButton, 0, ButtonStyles["fake_for_group"]*)

        ; - Stop -
        MainGUI.AddText("x830 y575 w45", "Stop:")
        holder := MainGUI.AddButton("x875 y570 w112 h25 Disabled")
        CreateImageButton(holder, 0, ButtonStyles["fake_for_group"]*)
        stopInput := MainGUI.AddEdit("Disabled x875 y570 w112 h25 Center", "")
        stopInput.SetRounded(5)
        stopInput.Value := BindToHotkey(stopBind)
        ; - Stop Bind -
        BindStopButton := MainGUI.AddButton("x992 y570 w25 h25", Chr(0xE104))
        BindStopButton.OnEvent("Click", BindHotkeyButton)
        CreateImageButton(BindStopButton, 0, ButtonStyles["fake_for_group"]*)

        ; - Pause -
        MainGUI.AddText("x830 y604 w45", "Pause:")
        holder := MainGUI.AddButton("x875 y599 w112 h25 Disabled")
        CreateImageButton(holder, 0, ButtonStyles["fake_for_group"]*)
        pauseInput := MainGUI.AddEdit("Disabled x875 y599 w112 h25 Center", "")
        pauseInput.SetRounded(5)
        pauseInput.Value := BindToHotkey(pauseBind)
        ; - Pause Bind -
        BindPauseButton := MainGUI.AddButton("x992 y599 w25 h25", Chr(0xE104))
        BindPauseButton.OnEvent("Click", BindHotkeyButton)
        CreateImageButton(BindPauseButton, 0, ButtonStyles["fake_for_group"]*)
    }

    Maintab2() {
        MainGUI.AddText("x852 y18 Center w141 h16", "Page 2")

        PreviousButton := mainGui.AddButton("x820 y10 w32 h32", "<")
        PreviousButton.OnEvent("Click", (*) => TabCtrl.Choose("Main"))
        CreateImageButton(PreviousButton, 0, ButtonStyles["default"]*)

        ;NextButton := mainGui.AddButton("x993 y10 w32 h32", ">")
        ;NextButton.OnEvent("Click", (*) => TabCtrl.Choose("MainTab2"))
        ;CreateImageButton(NextButton, 0, ButtonStyles["default"]*)

        ; --- Reconnect ---
        holder := MaingUI.AddButton("x820 y62 w205 h89 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y67 Center w197", "Reconnect")

        TestRCButton := mainGui.AddButton("x978 y69 w40 h19", "Test")
        TestRCButton.OnEvent("Click", (*) => testReconnect())
        CreateImageButton(TestRCButton, 0, ButtonStyles["default"]*)

        MainGUI.AddText("x830 y96 Left w193", "Private Server Link")
        inputholder := MainGUI.AddButton("x830 y116 w185 h25 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        PServerInput := MainGUI.AddEdit("x830 y116 w185 h25", "")
        PServerInput.Text := PServerURL
        PServerInput.OnEvent('Change', (*) => GUISave())
        PServerInput.SetRounded(5)

        ; --- Misc ---
        holder := MaingUI.AddButton("x820 y167 w205 h89 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y175 Center w197", "Misc")

        global RPCCheckbox := MainGUI.AddCheckBox("x830 y197 h" SGH " w" SGW)
        RPCCheckbox.Value := RichPresenceE
        RPCCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y197", " Discord Rich Presence")

        global StatWCheckbox := MainGUI.AddCheckBox("x830 y222 h" SGH " w" SGW)
        StatWCheckbox.Value := StatWebsiteE
        MainGUI.AddText("x845 y222", " Stats Website")

        OpenSWButton := MaingUI.AddButton("x968 y219 w50 h16 Center", "Open")
        CreateImageButton(OpenSWButton, 0, ButtonStyles["default"]*)

        ; --- Send Chat ---
        holder := MaingUI.AddButton("x820 y272 w205 h110 0x100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y277 Center w197 h15", "Send Chat")

        SCCheckbox := MainGUI.AddCheckBox(" x830 y302 h" SGH " w" SGW)
        SCCheckbox.Value := SendChatE
        SCCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y302 Left w79 h15", " Enabled")

        MainGUI.AddText("x830 y327 Left w193 h15", "Message")
        inputholder := MainGUI.AddButton("x830 y347 w185 h25 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        ChatInput := MainGUI.AddEdit("x830 y347 w185 h25", "")
        ChatInput.Text := chatContents
        ChatInput.OnEvent('Change', (*) => GUISave())
        ChatInput.SetRounded(7)

        ; --- DEBUG ---
        /*holder := MaingUI.AddButton("x820 y398 w205 h50 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        
        MainGUI.AddText("x824 y406 Center w197", "Debug")
        
        global DebugCheckbox := MainGUI.AddCheckBox("x830 y426 h" SGH " w" SGW)
        DebugCheckbox.Value := DEBUG
        DebugCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y426", " Enabled") */

    }
}

WaitForBind(Options := "T5") {
    global ih := InputHook(Options)
    if !InStr(Options, "V")
        ih.VisibleNonText := false
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    ih.Start()
    ih.Wait()
    return StrReplace(StrReplace(ih.EndMods . ih.EndKey, "<", ""), ">", "")
}

CancelInputHook() {
    global ih
    if (ih) {
        ih.Stop()
        return true
    } else {
        return false
    }
}

BindHotkey(BtnObj) {
    try {
        global CurrentBindsRecords
        ; TODO: cancel input hook, and set the button back to normal
        BtnObj.Text := Chr(0xE15B)
        CreateImageButton(BtnObj, 0, ButtonStyles["fake_for_group"]*)
        CurrentBindsRecords := BtnObj.Hwnd
        tbind := WaitForBind()
        if tbind != "" {
            if BtnObj == BindResizeButton {
                global resizeBind
                Hotkey(resizeBind, "off")
                resizeBind := tbind
                resizeInput.Text := BindToHotkey(tbind)
            }
            else if BtnObj == BindStartButton {
                global startBind
                Hotkey(startBind, "off")
                startBind := tbind
                startInput.Text := BindToHotkey(tbind)
            }
            else if BtnObj == BindStopButton {
                global stopBind
                Hotkey(stopBind, "off")
                stopBind := tbind
                stopInput.Text := BindToHotkey(tbind)
            }
            else if BtnObj == BindPauseButton {
                global pauseBind
                Hotkey(pauseBind, "off")
                pauseBind := tbind
                pauseInput.Text := BindToHotkey(tbind)
            }
            SaveCfg()
        }
        BtnObj.Text := Chr(0xE104)
        CreateImageButton(BtnObj, 0, ButtonStyles["fake_for_group"]*)
        CurrentBindsRecords := ""
    }
}
BindHotkeyButton(BtnObj, *) {
    BindHotkey(BtnObj)
}
BindToHotkey(keys) {
    return StrReplace(StrReplace(StrReplace(StrReplace(keys, "+", "Shift + "), "^", "Ctrl + "), "!", "Alt + "), "#",
    "Win + ")
}

SaveCfg(*) {
    GUISave()
    Hotkey(resizeBind, start_write_non_ui)
    Hotkey(startBind, start_write_non_ui)
    Hotkey(stopBind, start_write_non_ui)
    Hotkey(pauseBind, start_write_non_ui)
}

start_write_non_ui(*) {
    global status
    status := 1
    ;start_write(false)
}
