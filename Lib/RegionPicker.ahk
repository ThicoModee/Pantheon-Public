#Requires AutoHotkey v2.0

class RegionPicker {
    __New(hwnd, bitmap, point := false) {
        WinGetClientPos(&x, &y, , , "ahk_id " hwnd)
        this.X := x, this.Y := y, this.Target := hwnd
        this.Start := 0, this.Result := 0, this.Finished := false
        this.PointMode := point
        this.Window := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale", point ? "Select Roblox coordinates" : "Capture Roblox image")
        this.Window.MarginX := this.Window.MarginY := 0
        folder := A_ScriptDir "\data\developer"
        DirCreate(folder)
        path := folder "\selection.png"
        if Gdip_SaveBitmapToFile(bitmap, path) != 0
            throw Error("Could not prepare the region selection image.")
        this.Picture := this.Window.AddPicture("x0 y0 w800 h600 +0x100", path)
        this.Hud := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x08000020 -DPIScale +Owner" this.Window.Hwnd)
        this.Hud.BackColor := "29243F"
        this.Hud.SetFont("s12 cFFFFFF", "Segoe UI")
        this.Hud.AddText("x14 y8 w770 h40", point ? "SELECT COORDINATES   ·   Left click selects   ·   Escape cancels" : "CAPTURE IMAGE   ·   Drag a rectangle around the image   ·   Escape cancels")
        this.ConfirmHandler := ObjBindMethod(this, "ConfirmPoint")
        this.CursorHandler := ObjBindMethod(this, "Cursor")
        this.Mark := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x08000020 -DPIScale +Owner" this.Window.Hwnd)
        this.Mark.BackColor := "9189FA"
        WinSetTransparent(90, this.Mark)
        this.DownHandler := ObjBindMethod(this, "Down")
        this.MoveHandler := ObjBindMethod(this, "Move")
        this.UpHandler := ObjBindMethod(this, "Up")
        this.Window.OnEvent("Escape", ObjBindMethod(this, "Cancel"))
        this.Window.OnEvent("Close", ObjBindMethod(this, "Cancel"))
    }
    Select() {
        CoordMode("ToolTip", "Screen")
        OnMessage(0x201, this.DownHandler)
        OnMessage(0x200, this.MoveHandler)
        OnMessage(0x202, this.UpHandler)
        OnMessage(0x20, this.CursorHandler)
        if this.PointMode {
            HotIfWinActive("ahk_id " this.Window.Hwnd)
            Hotkey("LButton", this.ConfirmHandler, "On")
            HotIf()
        }
        started := A_TickCount
        try {
            this.Window.Show("x" this.X " y" this.Y " w800 h600")
            this.Hud.Show("NA x" this.X " y" Max(0, this.Y-58) " w800 h52")
            ToolTip(this.PointMode ? "Move to a point. Left click selects." : "Capture active: drag to select an image.", this.X+20, this.Y+24, 18)
            while !this.Finished && A_TickCount-started < 90000 && DllCall("IsWindow", "ptr", this.Target)
                Sleep(20)
            return this.Finished ? this.Result : 0
        } finally {
            DllCall("ReleaseCapture")
            ToolTip(, , , 18)
            OnMessage(0x201, this.DownHandler, 0)
            OnMessage(0x200, this.MoveHandler, 0)
            OnMessage(0x202, this.UpHandler, 0)
            OnMessage(0x20, this.CursorHandler, 0)
            if this.PointMode {
                HotIfWinActive("ahk_id " this.Window.Hwnd)
                Hotkey("LButton", "Off")
                HotIf()
            }
            this.Hud.Destroy(), this.Mark.Destroy(), this.Window.Destroy()
        }
    }
    ConfirmPoint(*) {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&x, &y)
        if x < this.X || x >= this.X+800 || y < this.Y || y >= this.Y+600 {
            ToolTip("Move inside the Roblox capture before selecting coordinates.", , , 18)
            return
        }
        this.Result := Map("x", x-this.X, "y", y-this.Y), this.Finished := true
    }
    Cursor(wParam, lParam, msg, hwnd) {
        if this.Accepts(hwnd) {
            DllCall("SetCursor", "ptr", DllCall("LoadCursorW", "ptr", 0, "ptr", 32515, "ptr"))
            return true
        }
    }
    Cancel(*) {
        this.Result := 0, this.Finished := true
    }
    Position() {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&x, &y)
        return [Max(0, Min(799, x-this.X)), Max(0, Min(599, y-this.Y))]
    }
    Accepts(hwnd) => hwnd == this.Window.Hwnd || hwnd == this.Picture.Hwnd
    Down(wParam, lParam, msg, hwnd) {
        if !this.Accepts(hwnd)
            return
        if this.PointMode
            return 0
        this.Start := this.Position()
        DllCall("SetCapture", "ptr", this.Window.Hwnd)
        this.Move(wParam, lParam, msg, hwnd)
        return 0
    }
    Move(wParam, lParam, msg, hwnd) {
        if !this.Accepts(hwnd)
            return
        if this.PointMode {
            p := this.Position()
            CoordMode("ToolTip", "Screen")
            ToolTip("X: " p[1] "   Y: " p[2] "`nLeft click selects · Escape cancels", this.X+p[1]+18, this.Y+p[2]+22, 18)
            return 0
        }
        if !this.Start
            return
        p := this.Position(), a := this.Start
        x := Min(a[1], p[1]), y := Min(a[2], p[2]), w := Abs(a[1]-p[1])+1, h := Abs(a[2]-p[2])+1
        this.Result := Map("x", x, "y", y, "width", w, "height", h)
        this.Mark.Show("NA x" this.X+x " y" this.Y+y " w" w " h" h)
        ToolTip(x ", " y " · " w " x " h " · Escape cancels", this.X, this.Y-35, 18)
        return 0
    }
    Up(wParam, lParam, msg, hwnd) {
        if !this.Accepts(hwnd) || !this.Start
            return
        this.Move(wParam, lParam, msg, hwnd)
        this.Finished := true
        return 0
    }
}
