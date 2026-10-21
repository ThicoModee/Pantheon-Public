#Requires AutoHotkey v2.0
#Include gui.ahk

MainTab() {
    global RPCCheckbox, StatWCheckbox
    global PServerInput
    global BindResizeButton, BindStartButton, BindStopButton, BindPauseButton
    global resizeInput, startInput, stopInput, pauseInput
    global SelectedMap, SelectedStage
    global MapSelectBG := Map(), ActSelectBG := Map()
    global acts := [1, 2, 3, 4, 5]
    global RaidMaps := [
        "Ant Kingdom (Midnight)",
        "Sacred Planet",
        "Strange Town", 
        "Ruined City (The Menace)",
        "Cursed Festival"
        "Future City (Tyrant's Invasion)",
        "Storm Hideout",
        "Future City",
        "Nightmare Train",
        "Sand Village"
    ]

    Maintab1()

    TabCtrl.UseTab("MainTab2")
    Maintab2()

    MainTab1() {
        ;MainGUI.AddText("x852 y18 Center w141 h16", "Page 1")

        ;PreviousButton := mainGui.AddButton("x820 y10 w32 h32", "<")
        ;PreviousButton.OnEvent("Click", (*) => TabCtrl.Choose("Main"))
        ;CreateImageButton(PreviousButton, 0, ButtonStyles["default"]*)

        ;NextButton := mainGui.AddButton("x993 y10 w32 h32", ">")
        ;NextButton.OnEvent("Click", (*) => TabCtrl.Choose("MainTab2"))
        ;CreateImageButton(NextButton, 0, ButtonStyles["default"]*)

        ; -- Select Map --
        holder := MaingUI.AddButton("x820 y10 w205 h84 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y15 w197 Center", "Raids")

        MainGUI.AddText("x830 y38 w35 Center ", "Stage")
        ActSelectBG.Set(1, MainGUI.AddButton("x865 y36 w40 h20 Disabled", Acts[RaidStageFM]))
        CreateImageButton(ActSelectBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        SelectedStage := mainGUI.AddDropDownList("x865 y36 w40 +0x4000000", Acts)
        SelectedStage.OnEvent("Change", (*) => DropDownListWorker(SelectedStage, Acts, ActSelectBG.Get(1)))
        SelectedStage.Text := Acts[RaidStageFM]

        MapSelectBG.Set(1, mainGUI.AddButton("x830 y64 Disabled w185 h20 Center", RaidMaps[RaidMapFM]))
        CreateImageButton(MapSelectBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        SelectedMap := mainGUI.AddDropDownList("x830 y64 w185 +0x4000000", RaidMaps)
        SelectedMap.OnEvent("Change", (*) => DropDownListWorker(SelectedMap, RaidMaps, MapSelectBG.Get(1)))
        SelectedMap.Text := RaidMaps[RaidMapFM]

        ; --- Reconnect ---
        holder := MaingUI.AddButton("x820 y102 w205 h89 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y110 Center w197", "Reconnect")

        TestRCButton := mainGui.AddButton("x978 y109 w40 h19", "Test")
        TestRCButton.OnEvent("Click", (*) => testReconnect())
        CreateImageButton(TestRCButton, 0, ButtonStyles["default"]*)

        MainGUI.AddText("x830 y136 Left w193", "Private Server Link")
        inputholder := MainGUI.AddButton("x831 y156 w183 h23 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        PServerInput := MainGUI.AddEdit("x830 y156 w185 h25", "")
        PServerInput.Text := PServerURL
        PServerInput.OnEvent('Change', (*) => GUISave())
        PServerInput.SetRounded(10)

        ; --- Misc ---
        holder := MaingUI.AddButton("x820 y199 w205 h100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y207 Center w197", "Misc")

        global RPCCheckbox := MainGUI.AddCheckBox("x830 y227 h" SGH " w" SGW)
        RPCCheckbox.Value := RichPresenceE
        RPCCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y228", " Discord Rich Presence")

        global StatWCheckbox := MainGUI.AddCheckBox("x830 y252 h" SGH " w" SGW)
        StatWCheckbox.Value := StatWebsiteE
        MainGUI.AddText("x845 y253", " Stats Website")

        OpenSWButton := MainGUI.AddButton("x968 y247 w50 h20 Center", "Open")
        CreateImageButton(OpenSWButton, 0, ButtonStyles["default"]*)

        global DebugCheckbox := MainGUI.AddCheckBox("x830 y276 h" SGH " w" SGW)
        DebugCheckbox.Value := DEBUG
        DebugCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y277", " Debug Mode")


        ; --- Congfigs ---
        holder := MaingUI.AddButton("x820 y307 w205 h110 0x100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y312 Center w197 h15", "Configs")

        MainGUI.AddText("x830 y335 w125", "Config Name")
        inputholder := MainGUI.AddButton("x830 y353 w125 h25 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        ConfigInput := MainGUI.AddEdit("x830 y353 w125 h25", "")
        ConfigInput.SetRounded(5)

        UploadButton := mainGui.AddButton("x960 y353 w55 h25", "Upload")
        CreateImageButton(UploadButton, 0, ButtonStyles["default"]*)

        LoadButton := mainGui.AddButton("x873 y386 w100 h25", "Load Config")
        CreateImageButton(LoadButton, 0, ButtonStyles["default"]*)

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