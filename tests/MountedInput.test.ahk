#Requires AutoHotkey v2.0
#Include ..\Lib\HubModel.ahk
#Include ..\Lib\Desktop.ahk
#Include ..\Lib\WindowFrame.ahk
#Include ..\Lib\vendor\WebView2\WebView2.ahk

try {
    folder := A_ScriptDir "\..\test-results\input-fixture-" A_TickCount
    DirCreate(folder)
    title := "Pantheon input fixture " A_TickCount
    script := '#Requires AutoHotkey v2.0`ng:=Gui("+Resize -DPIScale", "' title '")`ng.AddEdit("x20 y20 w200 h40", "Input fixture")`ng.Show("NA w640 h480")`nPersistent()`n'
    FileAppend(script, folder "\game.ahk", "UTF-8-RAW")
    Run('"' A_AhkPath '" /ErrorStdOut "' folder '\game.ahk"', folder, "Hide", &pid)
    game := WinWait(title, , 5)
    Assert(game, "fixture opened")
    host := Gui("-Caption +Resize -DPIScale", "Pantheon mount input test")
    HubFrame.Initialize(host)
    host.Show("NA x80 y80 w1100 h780")
    GameMount.Initialize(host)
    controller := WebView2.CreateControllerAsync(host.Hwnd, 0, folder "\webview").await2()
    web := controller.CoreWebView2
    web.NavigateToString('<body style="background:#202020;color:white">Real WebView2 over the game surface</body>')
    Sleep(300)
    GameMount.Attach(game)
    GameMount.Layout(Map("x", 60, "y", 100, "width", 800, "height", 600, "visible", 1))
    Assert(DllCall("GetAncestor", "ptr", game, "uint", 2, "ptr") == game, "Roblox keeps a native top-level input window")
    GameMount.Focus()
    WinGetClientPos(&x, &y, , , "ahk_id " game)
    hit := DllCall("WindowFromPoint", "int64", ((y+35)<<32)|((x+40)&0xFFFFFFFF), "ptr")
    Assert(hit == game || DllCall("IsChild", "ptr", game, "ptr", hit), "mouse hit reaches mounted game, not WebView")
    gameThread := DllCall("GetWindowThreadProcessId", "ptr", game, "ptr", 0, "uint")
    info := Buffer(8+6*A_PtrSize+16), NumPut("uint", info.Size, info)
    Assert(DllCall("GetGUIThreadInfo", "uint", gameThread, "ptr", info), "read fixture focus")
    focus := NumGet(info,8+A_PtrSize,"ptr")
    Assert(focus == game || DllCall("IsChild", "ptr", game, "ptr", focus), "keyboard focus reaches game process")
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " host.Hwnd)
    host.GetClientPos(&cx, &cy, &cw, &ch)
    Assert(wx==cx && wy==cy && ww==cw && wh==ch, "no leftover non-client frame sliver")
    GameMount.Release()
    Assert(DllCall("GetParent", "ptr", game, "ptr") == 0, "normal window remains independent after unpin")
    ProcessClose(pid)
    controller := web := 0
    host.Destroy()
    FileAppend("PASS: independent top-level pin over WebView2, separate-process mouse hit and foreground keyboard focus, frame-free client geometry, restored game.`n", "*")
    ExitApp(0)
} catch Error as err {
    try GameMount.Release()
    if IsSet(pid) && ProcessExist(pid)
        ProcessClose(pid)
    FileAppend("FAIL: " err.Message " (" err.Line ")`n", "**")
    ExitApp(1)
}
Assert(value, message) {
    if !value
        throw Error(message)
}
