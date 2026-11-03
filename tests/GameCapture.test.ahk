#Requires AutoHotkey v2.0
#Include ..\Lib\HubModel.ahk
#Include ..\Lib\Desktop.ahk
#Include ..\Lib\Developer.ahk

SetTitleMatchMode(2)
token := Gdip_Startup(), bitmap := 0
host := Gui("-DPIScale", "Capture fixture host"), fixture := Gui("-DPIScale", "Capture fixture game")
fixture.BackColor := "245A8E"
try {
    host.Show("w100 h100 x0 y0"), fixture.Show("w900 h650")
    GameMount.Initialize(host)
    WinGetPos(&ox, &oy, &ow, &oh, "ahk_id " fixture.Hwnd)
    bitmap := GameCapture.Bitmap(fixture.Hwnd)
    Assert(Gdip_GetImageWidth(bitmap) == 800 && Gdip_GetImageHeight(bitmap) == 600, "captures client pixels at 800 x 600")
    Assert((Gdip_GetPixel(bitmap, 400, 300) & 0xFFFFFF) == 0x245A8E, "visible screen capture contains rendered fixture colour")
    Gdip_DisposeImage(bitmap), bitmap := 0
    WinGetPos(&x, &y, &w, &h, "ahk_id " fixture.Hwnd)
    Assert(x == ox && y == oy && w == ow && h == oh, "unmounted position and dimensions restored")
    Assert(!(WinGetExStyle("ahk_id " fixture.Hwnd) & 8), "unmounted capture clears temporary topmost")
    GameMount.Attach(fixture.Hwnd)
    GameMount.Rect["visible"] := 0
    WinActivate("ahk_id " host.Hwnd)
    GameMount.Refresh()
    Assert(GameMount.Hidden && !DllCall("IsWindowVisible", "ptr", fixture.Hwnd), "fixture pinned and hidden on placement page")
    bitmap := GameCapture.Bitmap()
    Assert((Gdip_GetPixel(bitmap, 400, 300) & 0xFFFFFF) == 0x245A8E, "hidden pinned game can still be captured")
    Gdip_DisposeImage(bitmap), bitmap := 0
    Assert(!DllCall("IsWindowVisible", "ptr", fixture.Hwnd), "hidden pin state restored after capture")
    Assert(!(DllCall("GetWindowLongPtr", "ptr", fixture.Hwnd, "int", -20, "ptr") & 8), "hidden pin is not left topmost")
    GameMount.Release()
    fixture.BackColor := "000000"
    rejected := false, failure := ""
    try bitmap := GameCapture.Bitmap(fixture.Hwnd)
    catch Error as err {
        rejected := InStr(err.Message, "black frame"), failure := err.Message
    }
    Assert(rejected && !GameMount.Capturing, "black frames rejected and capture state reset: " failure)
    Assert(!(WinGetExStyle("ahk_id " fixture.Hwnd) & 8), "failed capture restores topmost")
    bitmap := Gdip_CreateBitmap(800, 600)
    Gdip_SetPixel(bitmap, 17, 19, 0xFFFFFFFF)
    Assert(!GameCapture.Black(bitmap), "a sparse nonblack frame is preserved")
    Gdip_DisposeImage(bitmap), bitmap := 0
    Assert(DeveloperTools.Pattern("|<>*99$2.c") == "|<>*99$2.c", "generated string accepted by bundled FindText")
    Assert(FindText().base64tobit("c") == "10", "FindText sentinel encoding agrees with renderer")
    rejected := false
    try DeveloperTools.Region(Map("x", 799, "y", 599, "width", 2, "height", 1))
    catch Error
        rejected := true
    Assert(rejected, "out of bounds image regions rejected")
    rejected := false
    try DeveloperTools.Capture()
    catch Error
        rejected := true
    Assert(rejected, "developer operations disabled unless opted in")
    FileAppend("PASS: visible client capture, hidden pinned capture, size/position/topmost restoration, black-frame failure, FindText compatibility, bounded regions, developer opt-in.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (line " err.Line ")`n", "**")
    ExitApp(1)
} finally {
    try GameMount.Release()
    if bitmap > 0
        Gdip_DisposeImage(bitmap)
    Gdip_Shutdown(token)
    fixture.Destroy(), host.Destroy()
}
ExitApp(0)
Assert(value, message) {
    if !value
        throw Error(message)
}
