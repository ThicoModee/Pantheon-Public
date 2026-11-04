#Requires AutoHotkey v2.0
#Include ..\Lib\framework\Runner.ahk
#Include ..\Lib\framework\RobloxEnvironment.ahk

fixture := Gui("-DPIScale +AlwaysOnTop", "Progress capture fixture")
fixture.BackColor := "245A8E"
fixture.Show("w200 h100")
try {
    WinActivate("ahk_id " fixture.Hwnd)
    Sleep(100)
    env := ProgressFixture(fixture.Hwnd, (*) => 0)
    started := A_TickCount
    samples := env.Progress(Map("x", 10, "y", 10, "width", 74, "height", 15))
    elapsed := A_TickCount-started
    if samples.Length != 555
        throw Error("Unexpected progress sample count.")
    for colour in samples
        if colour != 0x245A8E
            throw Error("Progress pixel colours or client coordinates were incorrect.")
    FileAppend("PASS: single-frame progress sampling preserves coordinates and RGB; " samples.Length " pixels in " elapsed " ms.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (line " err.Line ")`n", "**")
    ExitApp(1)
} finally fixture.Destroy()
ExitApp(0)
class ProgressFixture extends RobloxFlowEnvironment {
    Check() {
    }
}
