#Requires AutoHotkey v2.0
#Include ..\Lib\vendor\WebView2\WebView2.ahk
#Include ..\Lib\vendor\JSON.ahk
#Include ..\Lib\WindowFrame.ahk

try {
    g := Gui("-Caption +Resize -DPIScale", "Pantheon titlebar fixture")
    HubFrame.Initialize(g)
    g.Show("NA x80 y80 w1100 h780")
    controller := WebView2.CreateControllerAsync(g.Hwnd, 0, A_ScriptDir "\..\test-results\titlebar-webview-" A_TickCount).await2()
    web := controller.CoreWebView2
    web.Settings.IsNonClientRegionSupportEnabled := true
    if !web.Settings.IsNonClientRegionSupportEnabled
        throw Error("Native drag regions were not enabled.")
    web.SetVirtualHostNameToFolderMapping("pantheon.test", A_ScriptDir "\..\Lib\ui", 0)
    web.Navigate("https://pantheon.test/index.html")
    started := A_TickCount
    loop {
        Sleep(100)
        result := JSON.parse("[" web.ExecuteScriptAsync("!!document.querySelector('.app-header')").await2() "]")[1]
        if result
            break
        if A_TickCount - started > 8000
            throw Error("Titlebar did not load.")
    }
    region := JSON.parse("[" web.ExecuteScriptAsync("getComputedStyle(document.querySelector('.app-header')).getPropertyValue('app-region')").await2() "]")[1]
    if region != "drag"
        throw Error("Header drag region was not recognized.")
    region := JSON.parse("[" web.ExecuteScriptAsync("getComputedStyle(document.querySelector('[data-window=maximize]')).getPropertyValue('app-region')").await2() "]")[1]
    if region != "no-drag"
        throw Error("Window button was inside the drag region.")
    WinGetPos(&x, &y, &w, &h, "ahk_id " g.Hwnd)
    g.Maximize()
    if WinGetMinMax("ahk_id " g.Hwnd) != 1
        throw Error("Maximize failed.")
    g.Restore()
    WinGetPos(&rx, &ry, &rw, &rh, "ahk_id " g.Hwnd)
    if rx != x || ry != y || rw != w || rh != h
        throw Error("Restore geometry differs.")
    controller := web := 0
    g.Destroy()
    FileAppend("PASS: installed WebView2 supports native drag regions; real header and window-button regions recognized; maximize/restore geometry preserved.`n", "*")
    ExitApp(0)
} catch Error as err {
    FileAppend("FAIL: " err.Message " (" err.Line ")`n", "**")
    ExitApp(1)
}
