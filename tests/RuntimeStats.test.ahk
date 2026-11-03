#Requires AutoHotkey v2.0
#Include ..\Lib\Desktop.ahk
#Include ..\Lib\HubModel.ahk
#Include ..\Lib\EngineBridge.ahk

InitializeMacro() {
}
try {
    folder := A_ScriptDir "\..\test-results\runtime-stats-" A_TickCount
    DirCreate(folder)
    HubEngine.Folder := folder, HubEngine.Pid := DllCall("GetCurrentProcessId"), HubEngine.StartedAt := A_TickCount-2500
    IniWrite("starting", folder "\state.ini", "Engine", "State")
    Assert(HubEngine.Snapshot()["seconds"] >= 2 && HubEngine.StartedAt, "startup acknowledgement preserves the running clock")
    IniWrite("running", folder "\state.ini", "Engine", "State")
    Assert(HubEngine.Snapshot()["seconds"] >= 2, "runtime advances while running")
    PantheonBridge.Folder := folder
    PantheonBridge.Result(true), PantheonBridge.Result(false), PantheonBridge.Result(true)
    state := HubEngine.Snapshot()
    Assert(state["wins"] == 2 && state["losses"] == 1, "dashboard reads recorded wins and defeats")
    IniWrite("ready", folder "\state.ini", "Engine", "State")
    elapsed := HubEngine.Snapshot()["seconds"]
    Sleep(100)
    Assert(!HubEngine.StartedAt && HubEngine.Snapshot()["seconds"] == elapsed, "runtime freezes after completion")
    camera := Map("action", "camera", "zoomIn", 20, "zoomOut", 20, "tilt", 299)
    Assert(PlacementStore.CameraStep([Map("action", "outcome", "thenSteps", [camera])]) == camera, "alignment finds nested bird's-eye settings")
    FileAppend("PASS: runtime startup, completion freeze, session wins/defeats and camera selection.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (line " err.Line ")`n", "**")
    ExitApp(1)
}
ExitApp(0)
Assert(value, message) {
    if !value
        throw Error(message)
}
