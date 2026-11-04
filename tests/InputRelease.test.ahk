#Requires AutoHotkey v2.0

#Include ..\Lib\framework\Schema.ahk

#Include ..\Lib\framework\RobloxEnvironment.ahk



fixture := Gui("-DPIScale", "Input release fixture")

clicks := Map("value", 0)
button := fixture.AddButton("x20 y20 w100 h30", "Start")
button.OnEvent("Click", (*) => clicks["value"]++)
fixture.Show("w300 h100")

environment := ReleaseFixture(fixture.Hwnd, (*) => 0)

try {

    if GetKeyState("Shift", "P") || GetKeyState("Control", "P")

        throw Error("Release modifier keys before running this fixture.")

    WinActivate("ahk_id " fixture.Hwnd)

    environment.Key("Shift", true)

    Sleep(30)

    if !GetKeyState("Shift")

        throw Error("Synthetic Shift was not held.")

    environment.Release()

    Sleep(30)

    if GetKeyState("Shift")

        throw Error("Shift remained held after cleanup.")

    environment.Key("Control", true)

    environment.Suspend()

    if GetKeyState("Control")

        throw Error("Control remained held during pause.")

    SendMode("Input"), CoordMode("Mouse", "Client")
    environment.Move(50, 35)
    WinGetClientPos(&left, &top, , , "ahk_id " fixture.Hwnd)
    previousCoordinates := A_CoordModeMouse
    CoordMode("Mouse", "Screen"), MouseGetPos(&mx, &my)
    CoordMode("Mouse", previousCoordinates)
    if mx != left+50 || my != top+35
        throw Error("Client-relative movement did not reach the expected screen pixel.")
    environment.Click(50, 35)
    Sleep(100)
    if clicks["value"] != 1 || GetKeyState("LButton") || environment.Held.Has("LButton")
        throw Error("Timed click did not activate the button once and release the mouse.")

    if A_SendMode != "Input" || A_CoordModeMouse != "Client"
        throw Error("Click did not restore the caller's input mode and coordinates.")
    environment.Fail := true
    failed := false
    try environment.Click(50, 35)
    catch Error
        failed := true
    if !failed || GetKeyState("LButton") || environment.Held.Has("LButton")
        throw Error("Interrupted click failed to release the mouse button.")

    FileAppend("PASS: actual modifier state is released by cleanup and pause.`n", "*")

} catch Error as err {

    FileAppend("FAIL: " err.Message "`n", "**")

    ExitApp(1)

} finally {

    environment.Release()

    fixture.Destroy()

}

ExitApp(0)

class ReleaseFixture extends RobloxFlowEnvironment {
    Fail := false

    Check() {
        if this.Fail && this.Held.Has("LButton")
            throw Error("Simulated focus loss.")
    }

}
