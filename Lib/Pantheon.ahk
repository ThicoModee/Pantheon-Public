#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\HubModel.ahk
#Include %A_LineFile%\..\Desktop.ahk
#Include %A_LineFile%\..\WindowFrame.ahk
#Include %A_LineFile%\..\RunSettings.ahk
#Include %A_LineFile%\..\Developer.ahk
#Include %A_LineFile%\..\Placements.ahk
#Include %A_LineFile%\..\vendor\WebView2\WebView2.ahk

SetWorkingDir(A_ScriptDir)
SetTitleMatchMode(2)
if A_Args.Length && A_Args[1] == "--check" {
    FileAppend("Pantheon Hub and dependencies parsed successfully.`n", "*")
    ExitApp()
}
TraySetIcon(A_ScriptDir "\Lib\ui\assets\pantheon.ico")
global HostWindow := Gui("-Caption +Resize -DPIScale +MinSize1100x780", "Pantheon")
HubFrame.Initialize(HostWindow)
HostWindow.BackColor := "171717"
try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", HostWindow.Hwnd, "Int", 20, "Int*", 1, "Int", 4)
HostWindow.OnEvent("Close", CloseHub)
HostWindow.OnEvent("Size", ResizeHub)
global RecordingInput := false
global Controller := 0, Web := 0, Events := [], Dirty := false
global PageUrl := "https://pantheon.local/index.html"
HostWindow.Show("w1380 h900")
GameMount.Initialize(HostWindow)
HubEngine.Host := HostWindow
OnExit(CleanupDesktop)
try {
    MacroHub.Initialize()
    Controller := WebView2.CreateControllerAsync(HostWindow.Hwnd, 0, A_ScriptDir "\data\webview").await2()
    Web := Controller.CoreWebView2
    DeveloperTools.Report := (message) => Web.PostWebMessageAsJson(JSON.stringify(Map("event", "error", "message", message)))
    Web.SetVirtualHostNameToFolderMapping("pantheon.local", A_ScriptDir "\Lib\ui", 0)
    Web.Settings.AreHostObjectsAllowed := false
    Web.Settings.IsStatusBarEnabled := false
    Web.Settings.AreDefaultContextMenusEnabled := false
    Web.Settings.AreBrowserAcceleratorKeysEnabled := false
    Web.Settings.IsZoomControlEnabled := false
    Web.Settings.IsNonClientRegionSupportEnabled := true
    Events.Push(Web.NavigationStarting(GuardNavigation))
    Events.Push(Web.NewWindowRequested((sender, args) => args.Handled := true))
    Events.Push(Web.WebMessageReceived(HandleMessage))
    Web.Navigate(PageUrl)
    BindHubHotkeys()
    SetTimer(MaintainGameMount, 150)
} catch Error as err {
    MsgBox("Pantheon could not open.`n`n" err.Message "`n`nSee README.md for setup and WebView2 requirements.", "Pantheon", "Iconx")
    ExitApp(1)
}

ResizeHub(guiObj, minMax, width, height) {
    global Controller
    if minMax != -1 && Controller
        Controller.Fill()
}
MaintainGameMount() {
    global Web
    try GameMount.Refresh()
    catch Error as err {
        GameMount.Release()
        Web.PostWebMessageAsJson(JSON.stringify(Map("event", "error", "message", err.Message)))
    }
}
CloseHub(*) {
    global Dirty, Web, Controller, Events
    if Dirty && MsgBox("Close without saving your changes?", "Pantheon", "YesNo Icon?") != "Yes"
        return
    Events := [], Web := Controller := 0
    ExitApp()
}
GuardNavigation(sender, args) {
    global PageUrl
    if StrSplit(args.Uri, "#")[1] != PageUrl
        args.Cancel := true
}
HandleMessage(sender, args) {
    global PageUrl, Dirty, RecordingInput
    id := ""
    try {
        if StrSplit(args.Source, "#")[1] != PageUrl
            throw Error("Untrusted page source.")
        text := args.TryGetWebMessageAsString()
        if StrLen(text) > 2000000
            throw Error("Message is too large.")
        m := JSON.parse(text)
        if !(m is Map) || !(m["id"] is String) || StrLen(m["id"]) > 64
            throw Error("Invalid message.")
        id := m["id"]
        action := m["action"]
        switch action {
            case "snapshot":
                result := MacroHub.Snapshot()
            case "loadRunSettings": result := RunSettings.Load(m["mode"])
            case "saveRunSettings": result := RunSettings.Save(m["mode"], m["data"])
            case "testWebhook": result := RunSettings.TestWebhook()
            case "preferences":
                result := MacroHub.SavePreferences(m["data"])
                if !result["developer"]
                    DeveloperTools.Stop()
            case "developerCoordinates": result := DeveloperTools.Coordinates(m["data"])
            case "developerCapture": result := DeveloperTools.Capture()
            case "developerSelect": result := DeveloperTools.Capture(true)
            case "developerPickPoint": result := DeveloperTools.PickPoint()
            case "frameworkLoad":
                DeveloperTools.Require()
                result := MacroPackages.Load(m["data"])
            case "frameworkSave":
                raw := m["data"]
                FlowSchema.Keys(raw, "package|definition|revision")
                result := MacroPackages.Save(raw["package"], raw["definition"], raw["revision"])
            case "frameworkCatalog":
                DeveloperTools.Require()
                result := MacroPackages.Catalog()
            case "frameworkNew": result := MacroPackages.New()
            case "macroImportPreview": result := MacroPackages.Preview(m["data"])
            case "macroInstall": result := MacroPackages.Install(m["data"])
            case "macroExport": result := m["data"] is Map ? MacroPackages.ExportDraft(m["data"]) : MacroPackages.Export(m["data"])
            case "macroCatalogRefresh": result := MacroPackages.Catalog(true)
            case "macroSettingsLoad":
                definition := MacroPackages.Load(m["data"])["definition"]
                result := Map("specs", FlowSettings.Specs(definition), "values", MacroPackages.Values(m["data"]))
            case "macroSettingsSave": result := MacroPackages.SaveValues(m["mode"], m["data"])
            case "developerExport": result := DeveloperTools.Export(m["data"])
            case "developerCopy": result := DeveloperTools.Copy(m["data"])
            case "developerCopyPattern": result := DeveloperTools.CopyPattern(m["data"])
            case "developerTest": result := DeveloperTools.Test(m["data"])
            case "joinDiscord":
                Run("https://discord.gg/egqhwdXs6R")
                result := Map("opened", 1)
            case "launch", "selectWorkspace": result := MacroHub.SelectWorkspace(m["data"])
            case "mountLayout": result := GameMount.Layout(m["data"])
            case "mount": result := GameMount.Enable()
            case "detach":
                try HubEngine.Stop()
                finally result := GameMount.Release()
            case "startEngine":
                try result := HubEngine.Start(m["data"])
                catch Error as err {
                    HubEngine.Stop()
                    throw err
                }
            case "pauseEngine": result := HubEngine.Pause()
            case "stopEngine": result := HubEngine.Stop()
            case "focusRoblox": result := MacroHub.FocusRoblox()
            case "window": result := WindowAction(m["data"])
            case "placementPickPoint":
                MacroHub.Mode(m["mode"])
                result := DeveloperTools.PickPoint(false)
            case "loadPlacements": result := PlacementStore.Load(m["mode"])
            case "savePlacements": result := PlacementStore.Save(m["mode"], m["data"])
            case "placementFrame": result := PlacementStore.Frame(m["mode"], m["data"])
            case "alignPlacement": result := PlacementStore.Align(m["mode"])
            case "capturePlacement": result := PlacementStore.Capture(m["mode"], m["data"])
            case "importPlacementFrame": result := PlacementStore.ImportFrame(m["mode"], m["data"])
            case "playControlsLoad": result := PlayControls.Load()
            case "playControlsSave":
                if HubEngine.Busy()
                    throw Error("Stop the macro before changing in-game controls.")
                result := PlayControls.Save(m["data"])
            case "applyControls":
                result := HubControls.Apply(m["data"])
                BindHubHotkeys()
            case "recordingKey":
                RecordingInput := ProfileStore.Int(m["data"], 0, 1, "Key recording")
                result := Map("updated", 1)
            case "dirty":
                Dirty := ProfileStore.Int(m["data"], 0, 1, "Draft state")
                result := Map("updated", 1)
            default: throw Error("Unknown hub action.")
        }
        sender.PostWebMessageAsJson(JSON.stringify(Map("id", id, "ok", 1, "data", result)))
    } catch Error as err {
        sender.PostWebMessageAsJson(JSON.stringify(Map("id", id, "ok", 0, "error", err.Message)))
    }
}

CleanupDesktop(*) {
    try DeveloperTools.Stop()
    try HubEngine.Stop()
    try GameCapture.RestoreActive(true)
    try GameMount.Release()
}

WindowAction(action) {
    global HostWindow
    switch action {
        case "minimize": HostWindow.Minimize()
        case "maximize":
            if WinGetMinMax("ahk_id " HostWindow.Hwnd) == 1
                HostWindow.Restore()
            else
                HostWindow.Maximize()
        case "resize":
            DllCall("ReleaseCapture")
            PostMessage(0x112, 0xF008, 0, , "ahk_id " HostWindow.Hwnd)
        case "close": CloseHub()
        default: throw Error("Unknown window action.")
    }
    return Map("updated", 1)
}

BindHubHotkeys() {
    global HostWindow
    static registered := []
    HotIf(WorkspaceHotkeysEnabled)
    for key in registered
        try Hotkey(key, "Off")
    registered := []
    keys := HubControls.Read()
    for name, action in Map("resizeBind", "setup", "startBind", "toggle", "pauseBind", "pause") {
        Hotkey(keys[name], WorkspaceHotkey.Bind(action))
        registered.Push(keys[name])
    }
    HotIf()
}
WorkspaceHotkeysEnabled(*) {
    global HostWindow, RecordingInput
    return !RecordingInput && !GameMount.Capturing && GameMount.Rect["visible"] && (WinActive("ahk_id " HostWindow.Hwnd) || (GameMount.Hwnd && WinActive("ahk_id " GameMount.Hwnd)))
}
WorkspaceHotkey(action, *) {
    global Web
    try {
        switch action {
            case "setup":
                GameMount.Enable()
                GameMount.Focus()
            case "toggle":
                if HubEngine.State() == "running" || HubEngine.State() == "paused" {
                    HubEngine.Stop()
                    return
                }
                if Dirty
                    throw Error("Save your changes before starting with a shortcut.")
                HubEngine.Start(MacroHub.Config["selected"])
            case "stop": HubEngine.Stop()
            case "pause": HubEngine.Pause()
        }
    } catch Error as err {
        if action == "toggle"
            HubEngine.Stop()
        Web.PostWebMessageAsJson(JSON.stringify(Map("event", "error", "message", err.Message)))
    }
}
