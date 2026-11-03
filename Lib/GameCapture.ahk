#Requires AutoHotkey v2.0

class GameCapture {
    static Active := 0
    static Bitmap(hwnd := 0, probe := 0, prepare := 0) {
        hidden := A_DetectHiddenWindows
        DetectHiddenWindows(true)
        try return this.VisibleBitmap(hwnd, probe, prepare)
        finally DetectHiddenWindows(hidden)
    }
    static VisibleBitmap(hwnd, probe, prepare := 0) {
        if GameMount.Capturing
            throw Error("A Roblox capture is already in progress.")
        if HubEngine.Busy()
            throw Error("Stop the macro before capturing Roblox.")
        if !hwnd
            hwnd := GameMount.Hwnd ? GameMount.Hwnd : WinExist("ahk_exe RobloxPlayerBeta.exe")
        if !hwnd || !DllCall("IsWindow", "ptr", hwnd)
            throw Error("Open Roblox before capturing a screenshot. Pinning is optional.")
        target := "ahk_id " hwnd
        WinGetPos(&ox, &oy, &ow, &oh, target)
        state := WinGetMinMax(target), visible := DllCall("IsWindowVisible", "ptr", hwnd)
        topmost := WinGetExStyle(target) & 8
        foreground := DllCall("GetForegroundWindow", "ptr")
        bitmap := 0, GameMount.Capturing := true
        this.Active := Map("hwnd", hwnd, "x", ox, "y", oy, "width", ow, "height", oh, "state", state, "visible", visible, "topmost", topmost)
        try {
            WinShow(target)
            if state != 0
                WinRestore(target)
            monitor := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")
            info := Buffer(40, 0), NumPut("uint", 40, info)
            if !DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info)
                throw OSError(A_LastError)
            left := NumGet(info, 20, "int"), top := NumGet(info, 24, "int")
            right := NumGet(info, 28, "int"), bottom := NumGet(info, 32, "int")
            WinMove(left, top, 800, 600, target)
            WinGetClientPos(, , &cw, &ch, target)
            width := 1600-cw, height := 1200-ch
            if width > right-left || height > bottom-top
                throw Error("Roblox needs room for an 800 x 600 client area. Increase the display resolution or reduce Windows scaling.")
            if !DllCall("SetWindowPos", "ptr", hwnd, "ptr", -1, "int", left+(right-left-width)//2,
                "int", top+(bottom-top-height)//2, "int", width, "int", height, "uint", 0x40)
                throw OSError(A_LastError)
            WinActivate(target)
            if !WinWaitActive(target, , 2)
                throw Error("Could not bring Roblox forward. Close any open game dialogs and try again.")
            Sleep(500)
            loop 3 {
                WinGetClientPos(, , &w, &h, target)
                if w == 800 && h == 600
                    break
                WinGetPos(, , &outerWidth, &outerHeight, target)
                WinMove(, , outerWidth+800-w, outerHeight+600-h, target)
                Sleep(180)
            }
            WinGetClientPos(&x, &y, &w, &h, target)
            if w != 800 || h != 600
                throw Error("Roblox client is " w " x " h "; capture requires 800 x 600. Use windowed mode and try again.")
            if prepare
                prepare.Call(hwnd)
            DllCall("dwmapi\DwmFlush")
            bitmap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h, 0x40CC0020)
            if bitmap <= 0
                throw Error("Could not capture the visible Roblox client area.")
            if this.Black(bitmap)
                throw Error("Roblox returned a black frame. Wait until the game is visible in windowed mode and capture again.")
            if probe
                probe.Call(hwnd, bitmap)
            return bitmap
        } catch Error as err {
            if bitmap > 0
                Gdip_DisposeImage(bitmap)
            throw err
        } finally {
            try {
                this.RestoreActive()
                if foreground && DllCall("IsWindow", "ptr", foreground)
                    WinActivate("ahk_id " foreground)
            } finally {
                GameMount.Capturing := false
                GameMount.Refresh()
            }
        }
    }
    static RestoreActive(closing := false) {
        r := this.Active
        this.Active := 0
        if !r || !DllCall("IsWindow", "ptr", r["hwnd"])
            return
        target := "ahk_id " r["hwnd"]
        DllCall("SetWindowPos", "ptr", r["hwnd"], "ptr", !closing && r["topmost"] ? -1 : -2,
            "int", r["x"], "int", r["y"], "int", r["width"], "int", r["height"], "uint", 0x10)
        if r["state"] == -1
            WinMinimize(target)
        else if r["state"] == 1
            WinMaximize(target)
        if !r["visible"]
            WinHide(target)
    }
    static Black(bitmap) {
        width := Gdip_GetImageWidth(bitmap), height := Gdip_GetImageHeight(bitmap)
        if Gdip_LockBits(bitmap, 0, 0, width, height, &stride, &pixels, &data, 1) != 0
            throw Error("Could not inspect the captured pixels.")
        try {
            loop height {
                y := A_Index-1, row := pixels+y*stride
                corner := Min(8, width//4, height//4)
                inset := y < corner || y >= height-corner ? corner : 0
                loop width-inset*2
                    if NumGet(row, (A_Index-1+inset)*4, "uint") & 0xFFFFFF
                        return false
            }
            return true
        } finally {
            Gdip_UnlockBits(bitmap, &data)
        }
    }
}
