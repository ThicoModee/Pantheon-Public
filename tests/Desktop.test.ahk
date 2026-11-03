#Requires AutoHotkey v2.0

#Include ..\Lib\HubModel.ahk

#Include ..\Lib\Desktop.ahk

#Include ..\Lib\Developer.ahk



try {

    MacroPackages.Root := A_ScriptDir "\..\test-results\desktop-" A_TickCount

    MacroPackages.Bundled := MacroPackages.Root "\supplied"

    MacroHub.Config["developer"] := 1

    MacroPackages.Cached := 0

    created := MacroPackages.New(), id := created["package"]

    definition := created["definition"]

    definition["settings"] := Map("enabled", Map("label", "Enabled", "type", "toggle", "default", 0))

    definition["workflows"]["main"]["steps"] := [Map("id", "delay", "action", "delay", "durationMs", 10)]

    MacroPackages.Save(id, definition, 1)

    MacroPackages.SaveValues(id, Map("enabled", 1))

    host := Gui("-DPIScale", "Desktop host fixture"), game := Gui("-DPIScale", "Desktop game fixture")

    host.Show("w1100 h780"), game.Show("w900 h650")

    WinGetPos(&x, &y, &w, &h, "ahk_id " game.Hwnd)

    style := WinGetStyle("ahk_id " game.Hwnd)

    GameMount.Initialize(host), HubEngine.Host := host

    GameMount.Attach(game.Hwnd)

    Assert(DllCall("GetParent", "ptr", game.Hwnd, "ptr") == 0, "pin preserves independent game window")

    GameMount.Rect := Map("x", 200, "y", 80, "width", 800, "height", 600, "visible", 1)

    WinActivate("ahk_id " host.Hwnd), GameMount.Refresh()

    WinGetClientPos(, , &clientW, &clientH, "ahk_id " game.Hwnd)

    Assert(clientW == 800 && clientH == 600, "pin has reference client size")

    Assert(WinGetExStyle("ahk_id " game.Hwnd) & 0x40000, "pin preserves an independent taskbar entry")
    external := Gui("-DPIScale", "External app fixture")
    external.Show("w200 h100")
    WinActivate("ahk_id " external.Hwnd)
    WinWaitActive("ahk_id " external.Hwnd, , 2)
    GameMount.Refresh()
    Assert(DllCall("IsWindowVisible", "ptr", game.Hwnd) && !GameMount.Hidden, "switching away keeps Roblox visible")
    Assert(!(WinGetExStyle("ahk_id " game.Hwnd) & 8), "switching away clears topmost")
    external.Destroy()
    WinActivate("ahk_id " host.Hwnd), GameMount.Refresh()

    HubEngine.Start(id)

    started := A_TickCount

    while HubEngine.State() != "error" {

        if A_TickCount-started > 5000

            throw Error("Worker did not reject the non-Roblox fixture.")

        Sleep(25)

    }

    Assert(!HubEngine.Busy() && !MacroHub.AnyOpen(), "failed worker does not lock editing")

    savedAfterError := MacroPackages.Save(id, definition, 2)

    Assert(savedAfterError["revision"] == 3, "definition saves after runtime error")

    MacroPackages.SaveValues(id, Map("enabled", 0))

    captureToken := Gdip_Startup(), captureBitmap := 0

    try {

        game.BackColor := "245A8E"

        captureBitmap := GameCapture.Bitmap(game.Hwnd)

        Assert(captureBitmap > 0, "developer capture available after runtime error")

    } finally {

        if captureBitmap

            Gdip_DisposeImage(captureBitmap)

        Gdip_Shutdown(captureToken)

    }

    Assert(InStr(FileRead(HubEngine.Folder "\log.txt", "UTF-8"), "Roblox client is unavailable"), "worker rejects unrelated windows before input")

    Assert(MacroPackages.Read(HubEngine.Folder "\settings-values.json")["enabled"] == 1, "saved settings copied to session")

    Assert(MacroPackages.Read(HubEngine.Folder "\framework.json")["name"] == definition["name"], "definition copied to session")

    rejected := false

    try HubEngine.Send("untrusted")

    catch Error

        rejected := true

    Assert(rejected, "worker command allowlist preserved")

    originalToken := HubEngine.Token, HubEngine.Token := "00000000000000000000000000000000", rejected := false

    try HubEngine.Send("start")

    catch Error

        rejected := true

    HubEngine.Token := originalToken

    Assert(rejected, "session token checked")

    WinHide("ahk_id " game.Hwnd), GameMount.Hidden := true
    HubEngine.Stop(), GameMount.Release()
    Assert(DllCall("IsWindowVisible", "ptr", game.Hwnd), "release restores Roblox even when pin was hidden")

    WinGetPos(&restoredX, &restoredY, &restoredW, &restoredH, "ahk_id " game.Hwnd)

    Assert(restoredX == x && restoredY == y && restoredW == w && restoredH == h, "unpin restores geometry")

    Assert(WinGetStyle("ahk_id " game.Hwnd) == style && !(WinGetExStyle("ahk_id " game.Hwnd) & 8), "unpin restores style and clears topmost")

    FileAppend("PASS: pin and restoration, data worker/session snapshots, unrelated-window rejection, command allowlist and session token checks.`n", "*")

} catch Error as err {

    FileAppend("FAIL: " err.Message " (line " err.Line ")`n", "**")

    ExitApp(1)

} finally {

    try HubEngine.Stop()

    try GameMount.Release()

    if IsSet(game)

        game.Destroy()

    if IsSet(host)

        host.Destroy()

}

ExitApp(0)

Assert(value, message) {

    if !value

        throw Error(message)

}
