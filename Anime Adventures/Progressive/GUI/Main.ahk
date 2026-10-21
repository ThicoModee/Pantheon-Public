#Requires AutoHotkey v2.0
#Include gui.ahk

MainTab() {
    global RPCCheckbox, StatWCheckbox
    global PServerInput, WaveInput
    global BindResizeButton, BindStartButton, BindStopButton, BindPauseButton
    global resizeInput, startInput, stopInput, pauseInput
    global SelectedLegendMap, SelectedStartMap, selectedEndMap, SelectedMap, SelectedStartAct, SelectedEndAct, SelectedGamemode, SelectedLegendStage
    global MapSelectBG := Map(), ActSelectBG := Map()
    global gamemodes := ["Infinite", "Story", "Legend"]
    global acts := [1, 2, 3, 4, 5, 6]
    global StoryMaps := [
        "Planet Greenie",
        "Walled City",
        "Snowy Town",
        "Sand Village",
        "Navy Bay",
        "Fiend City",
        "Spirit World",
        "Ant Kingdom",
        "Magic Town",
        "Haunted Academy",
        "Magic Hills",
        "Space Center",
        "Alien Spaceship",
        "Fabled Kingdom",
        "Ruined City",
        "Puppet Island",
        "Virtual Dungeon",
        "Snowy Kingdom",
        "Dungeon Throne",
        "Mountain Temple",
        "Rain Village",
        "Shibuya District"
    ]
    global LegendMaps := [
        "Magic Hills (Elf Invasion)",
        "Spirit Invasion",
        "Space Center", 
        "Fabled Kingdom (Generals)",
        "Ruined City (Midnight)",
        "Virtual Dungeon (Bosses)",
        "Dungeon Throne",
        "Rain Village"
    ]

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

        ; -- Select Map --
        holder := MaingUI.AddButton("x820 y62 w205 h125 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y67 w197 Center", "Gamemode")

        GamemodeBG := mainGUI.AddButton("x830 y86 Disabled w70 h20 Center", gamemodes[GamemodeFM])
        CreateImageButton(GamemodeBG, 0, ButtonStyles["fake_for_group"]*)
        SelectedGamemode := mainGUI.AddDropDownList("x830 y86 w70 +0x4000000", gamemodes)
        SelectedGamemode.OnEvent("Change", (*) => GamemodeChanged())
        SelectedGamemode.Text := gamemodes[GamemodeFM]

        GamemodeText := MainGUI.AddText("x824 y110 w197 Center", gamemodes[GamemodeFM])
        divider := MaingUI.AddButton("x833 y127 w180 h4 Disabled", "")
        CreateImageButton(divider, 0, ButtonStyles["divider"]*)

        ; INFINITE
        MainGUI.AddText("x830 y138 w75 vInfiniteWaveText", "End at wave")
        inputholder := MainGUI.AddButton("x901 y137 w48 h18 Disabled vInfiniteInputHolder")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        WaveInput := MainGUI.AddEdit("x900 y136 w50 h20 Center vInfiniteWaveInput", "")
        WaveInput.Text := InfiniteWaves
        WaveInput.OnEvent('Change', (*) => GUISave())
        WaveInput.SetRounded(7)

        MapSelectBG.Set(1, mainGUI.AddButton("x830 y161 Disabled w185 h20 Center vInfiniteMapButton", StoryMaps[InfiniteMapFM]))
        CreateImageButton(MapSelectBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        SelectedMap := mainGUI.AddDropDownList("x830 y161 w185 +0x4000000 vInfiniteMapDropdown", StoryMaps)
        SelectedMap.OnEvent("Change", (*) => DropDownListWorker(SelectedMap, StoryMaps, MapSelectBG.Get(1)))
        SelectedMap.Text := StoryMaps[InfiniteMapFM]

        global PortalCheckbox := MainGUI.AddCheckBox("vPortalCheckbox x975 y100 h" SGH " w" SGW)
        PortalCheckbox.Value := PortalFarmE
        PortalCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("vPortalCheckboxText x947 y84", "Farm Portal")

        ; STORY
        MainGUI.AddText("x846 y137 w50 Center vStoryStartText", "Start")
        MapSelectBG.Set(2, mainGUI.AddButton("x830 y157 Disabled w83 h20 Center -Wrap vStoryStartMapButton", StoryMaps[StoryStartMapFM]))
        CreateImageButton(MapSelectBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        SelectedStartMap := mainGUI.AddDropDownList("x830 y157 w83 +0x4000000 vStoryStartMapDropdown", StoryMaps)
        SelectedStartMap.OnEvent("Change", (*) => DropDownListWorker(SelectedStartMap, StoryMaps, MapSelectBG.Get(2)))
        SelectedStartMap.Text := StoryMaps[StoryStartMapFM]

        ActSelectBG.Set(1, mainGUI.AddButton("x893 y135 Disabled w20 h20 Center vStoryStartActButton", Acts[StoryStartActFM]))
        CreateImageButton(ActSelectBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        SelectedStartAct := mainGUI.AddDropDownList("x893 y135 w20 +0x4000000 vStoryStartActDropdown", Acts)
        SelectedStartAct.OnEvent("Change", (*) => DropDownListWorker(SelectedStartAct, Acts, ActSelectBG.Get(1)))
        SelectedStartAct.Text := Acts[StoryStartActFM]

        MainGUI.AddText("x949 y137 w50 Center vStoryEndText", "End")
        MapSelectBG.Set(3, mainGUI.AddButton("x933 y157 Disabled w83 h20 Center -Wrap vStoryEndMapButton", StoryMaps[StoryEndMapFM]))
        CreateImageButton(MapSelectBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        SelectedEndMap := mainGUI.AddDropDownList("x933 y157 w83 +0x4000000 vStoryEndMapDropdown", StoryMaps)
        SelectedEndMap.OnEvent("Change", (*) => DropDownListWorker(SelectedEndMap, StoryMaps, MapSelectBG.Get(3)))
        SelectedEndMap.Text := StoryMaps[StoryEndMapFM]

        ActSelectBG.Set(2, mainGUI.AddButton("x933 y135 Disabled w20 h20 Center vStoryEndActButton", Acts[StoryEndActFM]))
        CreateImageButton(ActSelectBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        SelectedEndAct := mainGUI.AddDropDownList("x933 y135 w20 +0x4000000 vStoryEndActDropdown", Acts)
        SelectedEndAct.OnEvent("Change", (*) => DropDownListWorker(SelectedEndAct, Acts, ActSelectBG.Get(2)))
        SelectedEndAct.Text := Acts[StoryEndActFM]

        ; LEGEND
        MainGUI.AddText("x830 y138 w35 Center vLegendActText", "Stage")
        ActSelectBG.Set(3, MainGUI.AddButton("x865 y136 w40 h20 Disabled vLegendInputHolder", Acts[LegendStageFM]))
        CreateImageButton(ActSelectBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        SelectedLegendStage := mainGUI.AddDropDownList("x865 y136 w40 +0x4000000 vLegendActInput", Acts)
        SelectedLegendStage.OnEvent("Change", (*) => DropDownListWorker(SelectedLegendStage, Acts, ActSelectBG.Get(3)))
        SelectedLegendStage.Text := Acts[LegendStageFM]

        MapSelectBG.Set(4, mainGUI.AddButton("x830 y161 Disabled w185 h20 Center vLegendMapButton", LegendMaps[LegendMapFM]))
        CreateImageButton(MapSelectBG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        SelectedLegendMap := mainGUI.AddDropDownList("x830 y161 w185 +0x4000000 vLegendMapDropdown", LegendMaps)
        SelectedLegendMap.OnEvent("Change", (*) => DropDownListWorker(SelectedLegendMap, LegendMaps, MapSelectBG.Get(4)))
        SelectedLegendMap.Text := LegendMaps[LegendMapFM]
        
        HideAllGamemodeElements()
        ShowGamemodeElements(gamemodes[GamemodeFM])

        GamemodeChanged() {
            DropDownListWorker(SelectedGamemode, gamemodes, GamemodeBG)
            GamemodeText.Text := selectedGamemode.Text
            
            HideAllGamemodeElements()
            ShowGamemodeElements(selectedGamemode.Text)
            
            GUISave()
        }

        ; --- Reconnect ---
        holder := MaingUI.AddButton("x820 y203 w205 h89 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y211 Center w197", "Reconnect")

        TestRCButton := mainGui.AddButton("x978 y210 w40 h19", "Test")
        TestRCButton.OnEvent("Click", (*) => testReconnect())
        CreateImageButton(TestRCButton, 0, ButtonStyles["default"]*)

        MainGUI.AddText("x830 y237 Left w193", "Private Server Link")
        inputholder := MainGUI.AddButton("x831 y258 w183 h23 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        PServerInput := MainGUI.AddEdit("x830 y257 w185 h25", "")
        PServerInput.Text := PServerURL
        PServerInput.OnEvent('Change', (*) => GUISave())
        PServerInput.SetRounded(10)

        ; --- Misc ---
        holder := MaingUI.AddButton("x820 y308 w205 h100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y316 Center w197", "Misc")

        global RPCCheckbox := MainGUI.AddCheckBox("x830 y336 h" SGH " w" SGW)
        RPCCheckbox.Value := RichPresenceE
        RPCCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y336", " Discord Rich Presence")

        global StatWCheckbox := MainGUI.AddCheckBox("x830 y361 h" SGH " w" SGW)
        StatWCheckbox.Value := StatWebsiteE
        MainGUI.AddText("x845 y361", " Stats Website")

        OpenSWButton := MainGUI.AddButton("x968 y356 w50 h20 Center", "Open")
        CreateImageButton(OpenSWButton, 0, ButtonStyles["default"]*)

        global DebugCheckbox := MainGUI.AddCheckBox("x830 y385 h" SGH " w" SGW)
        DebugCheckbox.Value := DEBUG
        DebugCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y385", " Debug Mode")


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

HideAllGamemodeElements() {
    ;MainGUI[""].Visible := false
    MainGUI["InfiniteWaveText"].Visible := false
    MainGUI["InfiniteInputHolder"].Visible := false
    MainGUI["InfiniteWaveInput"].Visible := false
    MainGUI["InfiniteMapButton"].Visible := false
    MainGUI["InfiniteMapDropdown"].Visible := false
    MainGUI["PortalCheckbox"].Visible := false
    MainGUI["PortalCheckboxText"].Visible := false
    
    MainGUI["StoryStartText"].Visible := false
    MainGUI["StoryStartMapButton"].Visible := false
    MainGUI["StoryStartMapDropdown"].Visible := false
    MainGUI["StoryStartActButton"].Visible := false
    MainGUI["StoryStartActDropdown"].Visible := false
    MainGUI["StoryEndText"].Visible := false
    MainGUI["StoryEndMapButton"].Visible := false
    MainGUI["StoryEndMapDropdown"].Visible := false
    MainGUI["StoryEndActButton"].Visible := false
    MainGUI["StoryEndActDropdown"].Visible := false
    
    MainGUI["LegendActText"].Visible := false
    MainGUI["LegendInputHolder"].Visible := false
    MainGUI["LegendActInput"].Visible := false
    MainGUI["LegendMapButton"].Visible := false
    MainGUI["LegendMapDropdown"].Visible := false
}

ShowGamemodeElements(gamemode) {
    if (gamemode = "Infinite") {
        MainGUI["InfiniteWaveText"].Visible := true
        MainGUI["InfiniteInputHolder"].Visible := true
        MainGUI["InfiniteWaveInput"].Visible := true
        MainGUI["InfiniteMapButton"].Visible := true
        MainGUI["InfiniteMapDropdown"].Visible := true
        MainGUI["PortalCheckbox"].Visible := true
        MainGUI["PortalCheckboxText"].Visible := true
    }
    else if (gamemode = "Story") {
        MainGUI["StoryStartText"].Visible := true
        MainGUI["StoryStartMapButton"].Visible := true
        MainGUI["StoryStartMapDropdown"].Visible := true
        MainGUI["StoryStartActButton"].Visible := true
        MainGUI["StoryStartActDropdown"].Visible := true
        MainGUI["StoryEndText"].Visible := true
        MainGUI["StoryEndMapButton"].Visible := true
        MainGUI["StoryEndMapDropdown"].Visible := true
        MainGUI["StoryEndActButton"].Visible := true
        MainGUI["StoryEndActDropdown"].Visible := true
    }
    else if (gamemode = "Legend") {
        MainGUI["LegendActText"].Visible := true
        MainGUI["LegendInputHolder"].Visible := true
        MainGUI["LegendActInput"].Visible := true
        MainGUI["LegendMapButton"].Visible := true
        MainGUI["LegendMapDropdown"].Visible := true
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

SaveRegistryToJSON(RegPath, OutputFile) {
    Log("Saving registry to JSON...")

    RegData := ReadRegistry(RegPath)
    JSON := JsonStringify(RegData)

    try {
        FileDelete(OutputFile)
        Log("Deleted old output file (if existed).")
    } catch {
        Log("⚠️ Warning: Could not delete old file.")
    }

    FileAppend(JSON, OutputFile, "UTF-8")
    Log("✅ Registry data saved successfully!")
}

ReadRegistry(Path) {
    Data := Map()
    Data["RegistryPath"] := Path
    Log("Reading registry path: " Path)

    for Name in GetRegistryValues(Path) {
        if InStr(Name, "Runtime") {
            Log("⚠️ Skipping value (contains 'Runtime'): " Name)
            continue
        }

        try {
            Value := RegRead(Path, Name)
            Log("Found value: " Name " = " Value)
            Data[Name] := Value
        } catch {
            Log("⚠️ Warning: Could not read value: " Name)
        }
    }

    for SubKey in GetSubkeys(Path) {
        Data[SubKey] := ReadRegistry(Path "\" SubKey)
    }

    return Data
}

GetRegistryValues(Path) {
    Values := []
    try {
        loop reg, Path, "V" {
            Values.Push(A_LoopRegName)
        }
    } catch {
        Log("⚠️ Warning: Could not retrieve values for path: " Path)
    }
    return Values
}

GetSubkeys(Path) {
    Subkeys := []
    Log("Getting subkeys for path: " Path)

    try {
        loop reg, Path, "K" {
            Subkeys.Push(A_LoopRegName)
            Log("Found subkey: " A_LoopRegName)
        }
    } catch {
        Log("⚠️ Warning: Could not retrieve subkeys for path: " Path)
    }

    return Subkeys
}

HasSubkeys(Path) {
    try {
        loop reg, Path, "K"
            return true
    } catch {
        return false
    }
    return false
}

HasValues(Path) {
    try {
        loop reg, Path, "V"
            return true
    } catch {
        return false
    }
    return false
}

JsonStringify(Data) {
    JSON := "{"
    for Key, Value in Data {
        JSON .= '"' Key '":' (IsObject(Value) ? JsonStringify(Value) : '"' Value '"') ","
    }
    return SubStr(JSON, 1, -1) "}"
}

Log(Text) {
    Timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    FileAppend(Timestamp " - " Text "`n", A_ScriptDir "\log.txt", "UTF-8")
}
