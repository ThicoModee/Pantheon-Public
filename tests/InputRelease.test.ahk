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

    environment.Click(50, 35)
    Sleep(100)
    if clicks["value"] != 1 || GetKeyState("LButton") || environment.Held.Has("LButton")
        throw Error("Timed click did not activate the button once and release the mouse.")

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

    Check() {

    }

}
