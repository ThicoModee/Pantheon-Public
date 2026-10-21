#Requires AutoHotkey v2.0
#Include gui.ahk

MainTab() {
    global SCCheckbox, RandomConCheckbox, RPCCheckbox, StatWCheckbox
    global ChatInput, PServerInput
    global BindResizeButton, BindStartButton, BindStopButton, BindPauseButton
    global resizeInput, startInput, stopInput, pauseInput
    global MatchmakeMode, SelectedContract

    ContractList := ["1", "2", "3", "4", "5", "6"]

    ; --- Send Chat ---
    ; - Box & Title -
    holder := MaingUI.AddButton("x820 y10 w205 h110 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)

    MainGUI.AddText("x824 y15 w197 Center", "Send Chat")

    ; - Send Chat System -
    SCCheckbox := MainGUI.AddCheckBox("x830 y45 h" SGH " w" SGW)
    SCCheckbox.Value := SendChatE
    SCCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y45", " Enabled")

    MainGUI.AddText("x830 y65 w193", "Message")

    BG := MainGUI.AddButton("x830 y85 w185 h25 Disabled")
    CreateImageButton(BG, 0, ButtonStyles["fake_for_group"]*)
    ChatInput := MainGUI.AddEdit("x830 y85 w185 h25", "")
    ChatInput.Text := chatContents
    ChatInput.OnEvent('Change', (*) => GUISave())
    ChatInput.SetRounded(5)

    ;--- Contract Settings ---
    holder := MaingUI.AddButton("x820 y128 w205 h90 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)

    MainGUI.AddText("x824 y133 w197 Center", "Contracts")

    RandomConCheckbox := MainGUI.AddCheckBox("x830 y158 h" SGH " w" SGW)
    ;RandomConCheckbox.Value := RandomConE
    ;RandomConCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y158", " Random")

    MainGUI.AddText("x830 y188 w121", "Selected Contract")
    ContractBG := mainGUI.AddButton("x950 y183 Disabled w65 h25 Center", ContractList[PageFM])
    CreateImageButton(ContractBG, 0, ButtonStyles["fake_for_group"]*)
    SelectedContract := mainGUI.AddDropDownList("x950 y183 w65 +0x4000000", ContractList)
    SelectedContract.OnEvent("Change", (*) => DropDownListWorker(SelectedContract, ContractList, ContractBG))
    SelectedContract.Text := ContractList[PageFM]

    ; --- Misc ---
    holder := MaingUI.AddButton("x820 y232 w205 h89 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)

    MainGUI.AddText("x824 y240 Center w197", "Misc")

    RPCCheckbox := MainGUI.AddCheckBox("x830 y262 h" SGH " w" SGW)
    RPCCheckbox.Value := RichPresenceE
    RPCCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y262", " Discord Rich Presence")

    global StatWCheckbox := MainGUI.AddCheckBox("x830 y287 h" SGH " w" SGW)
    StatWCheckbox.Value := StatWebsiteE
    MainGUI.AddText("x845 y287", " Stats Website")

    OpenSWButton := MaingUI.AddButton("x968 y284 w50 h16 Center", "Open")
    CreateImageButton(OpenSWButton, 0, ButtonStyles["default"]*)

    ;--- Reconnect Settings ---
    holder := MaingUI.AddButton("x820 y329 w205 h89 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)

    MainGUI.AddText("x824 y334 Center w197", "Reconnect")

    TestRCButton := mainGui.AddButton("x978 y336 w40 h19", "Test")
    TestRCButton.OnEvent("Click", (*) => testReconnect())
    CreateImageButton(TestRCButton, 0, ButtonStyles["default"]*)

    MainGUI.AddText("x830 y363 Left w193", "Private Server Link")
    inputholder := MainGUI.AddButton("x830 y383 w185 h25 Disabled")
    CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
    PServerInput := MainGUI.AddEdit("x830 y383 w185 h25", "")
    PServerInput.Text := PServerURL
    PServerInput.OnEvent('Change', (*) => GUISave())
    PServerInput.SetRounded(5)

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
}

start_write_non_ui(*) {
    global status
    status := 1
    ;start_write(false)
}
