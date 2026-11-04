#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\vendor\FindText.ahk
#Include %A_LineFile%\..\RegionPicker.ahk
#Include %A_LineFile%\..\GameCapture.ahk
#Include %A_LineFile%\..\vendor\Gdip_All.ahk

class DeveloperTools {
    static FramePath := A_ScriptDir "\data\developer\capture.png"
    static Viewing := false
    static Tick := ObjBindMethod(DeveloperTools, "Update")
    static CopyKey := ObjBindMethod(DeveloperTools, "CopyPosition")
    static LastPosition := ""
    static Matches := []
    static Selection := 0
    static Report := (message) => MsgBox(message, "Pantheon", "Iconx")

    static Require() {
        if !MacroHub.Config.Get("developer", 0)
            throw Error("Enable developer mode in Settings first.")
    }
    static Coordinates(enabled) {
        this.Require()
        ProfileStore.Int(enabled, 0, 1, "Coordinate viewer")
        if enabled {
            this.Viewing := true
            Hotkey("^+c", this.CopyKey, "On")
            SetTimer(this.Tick, 80)
        } else
            this.Stop()
        return Map("enabled", enabled)
    }
    static Stop() {
        SetTimer(this.Tick, 0)
        if this.Viewing
            Hotkey("^+c", "Off")
        this.Viewing := false
        ToolTip(, , , 19)
    }
    static Update() {
        if GameMount.Capturing {
            ToolTip(, , , 19)
            return
        }
        if !MacroHub.Config.Get("developer", 0) {
            this.Stop()
            return
        }
        try {
            CoordMode("Mouse", "Screen"), CoordMode("Pixel", "Screen"), CoordMode("ToolTip", "Screen")
            MouseGetPos(&x, &y)
            text := "Screen: " x ", " y
            hwnd := GameMount.Hwnd ? GameMount.Hwnd : WinExist("ahk_exe RobloxPlayerBeta.exe")
            if hwnd && DllCall("IsWindowVisible", "ptr", hwnd) {
                WinGetClientPos(&left, &top, &w, &h, "ahk_id " hwnd)
                text .= "`nRoblox client: " x-left ", " y-top "  (" w " x " h ")"
            } else if hwnd
                text .= "`nRoblox client: hidden"
            text .= "`nRGB: " Format("0x{:06X}", PixelGetColor(x, y))
            this.LastPosition := text
            ToolTip(text "`nCtrl+Shift+C: copy", x+20, y+24, 19)
        } catch Error as err {
            this.Stop()
            this.Report.Call("Coordinate viewer stopped: " err.Message)
        }
    }
    static CopyPosition(*) {
        A_Clipboard := this.LastPosition
    }
    static Capture(select := false) {
        this.Require()
        ToolTip(, , , 19)
        SetTimer(this.Tick, 0)
        token := Gdip_Startup(), bitmap := 0
        try {
            this.Selection := 0
            bitmap := GameCapture.Bitmap(0, select ? ObjBindMethod(this, "Pick") : 0)
            if select && !this.Selection
                return Map("cancelled", 1)
            SplitPath(this.FramePath, , &folder)
            DirCreate(folder)
            if Gdip_SaveBitmapToFile(bitmap, this.FramePath) != 0
                throw Error("Could not save the developer capture.")
            result := this.Frame()
            if select
                result["region"] := this.Selection
            return result
        } finally {
            if bitmap > 0
                Gdip_DisposeImage(bitmap)
            Gdip_Shutdown(token)
            if this.Viewing
                SetTimer(this.Tick, 80)
        }
    }
    static Pick(hwnd, bitmap) {
        this.Selection := RegionPicker(hwnd, bitmap).Select()
    }
    static PickPoint(requireDeveloper := true) {
        if requireDeveloper
            this.Require()
        this.Selection := 0
        token := Gdip_Startup(), bitmap := 0
        SetTimer(this.Tick, 0), ToolTip(, , , 19)
        if this.Viewing
            Hotkey("^+c", "Off")
        try {
            bitmap := GameCapture.Bitmap(0, ObjBindMethod(this, "Point"))
            return this.Selection ? this.Selection : Map("cancelled", 1)
        } finally {
            if bitmap > 0
                Gdip_DisposeImage(bitmap)
            Gdip_Shutdown(token)
            if this.Viewing {
                Hotkey("^+c", this.CopyKey, "On")
                SetTimer(this.Tick, 80)
            }
        }
    }
    static Point(hwnd, bitmap) => this.Selection := RegionPicker(hwnd, bitmap, true).Select()
    static Frame() {
        bytes := FileRead(this.FramePath, "RAW")
        DllCall("crypt32\CryptBinaryToStringW", "ptr", bytes, "uint", bytes.Size, "uint", 0x40000001, "ptr", 0, "uint*", &chars := 0)
        text := Buffer(chars*2)
        if !DllCall("crypt32\CryptBinaryToStringW", "ptr", bytes, "uint", bytes.Size, "uint", 0x40000001, "ptr", text, "uint*", &chars)
            throw Error("Could not read the developer capture.")
        return Map("image", "data:image/png;base64," StrGet(text, "UTF-16"))
    }
    static Region(raw) {
        if !(raw is Map)
            throw ValueError("Select an image region first.")
        x := ProfileStore.Int(raw["x"], 0, 799, "X"), y := ProfileStore.Int(raw["y"], 0, 599, "Y")
        w := ProfileStore.Int(raw["width"], 1, 800-x, "Width"), h := ProfileStore.Int(raw["height"], 1, 600-y, "Height")
        return Map("x", x, "y", y, "width", w, "height", h)
    }
    static Copy(raw) {
        this.Require()
        r := this.Region(raw)
        A_Clipboard := "x := " r["x"] ", y := " r["y"] "`nw := " r["width"] ", h := " r["height"]
            . "`nleft := " r["x"] ", top := " r["y"] ", right := " r["x"]+r["width"]-1 ", bottom := " r["y"]+r["height"]-1
            . "`nclickX := " r["x"]+r["width"]//2 ", clickY := " r["y"]+r["height"]//2
        return Map("copied", 1)
    }
    static Pattern(raw) {
        if !(raw is String) || StrLen(raw) > 80100 || !RegExMatch(raw, "^\|<>\*(\d{1,3})\$(\d{1,3})\.([0-9+/A-Za-z]+)$", &m)
            throw ValueError("Invalid FindText grayscale pattern.")
        threshold := Integer(m[1]), width := Integer(m[2])
        if threshold > 255 || width < 1 || width > 800
            throw ValueError("Invalid FindText dimensions or threshold.")
        bits := FindText().base64tobit(m[3])
        if StrLen(bits) < width || Mod(StrLen(bits), width) || StrLen(bits)//width > 600
            throw ValueError("Invalid FindText pattern height.")
        return raw
    }
    static CopyPattern(raw) {
        this.Require()
        A_Clipboard := this.Pattern(raw)
        return Map("copied", 1)
    }
    static Test(raw) {
        this.Require()
        pattern := this.Pattern(raw["pattern"])
        tolerance := ProfileStore.Int(raw["tolerance"], 0, 20, "Mismatch percentage")/100
        region := this.Region(raw.Get("region", Map("x", 0, "y", 0, "width", 800, "height", 600)))
        this.Matches := []
        token := Gdip_Startup(), bitmap := 0
        ToolTip(, , , 19), SetTimer(this.Tick, 0)
        try {
            bitmap := GameCapture.Bitmap(0, ObjBindMethod(this, "Search", pattern, tolerance, region))
            return Map("matches", this.Matches)
        } finally {
            if bitmap > 0
                Gdip_DisposeImage(bitmap)
            Gdip_Shutdown(token)
            if this.Viewing
                SetTimer(this.Tick, 80)
        }
    }
    static Search(pattern, tolerance, region, hwnd, bitmap := 0) {
        WinGetClientPos(&left, &top, &w, &h, "ahk_id " hwnd)
        errorRate := tolerance ? tolerance : 0.000000001
        found := FindText(&x, &y, left+region["x"], top+region["y"], left+region["x"]+region["width"]-1, top+region["y"]+region["height"]-1, errorRate, errorRate, pattern)
        if found
            for match in found {
                if this.Matches.Length >= 100
                    break
                this.Matches.Push(Map("x", match.x-left, "y", match.y-top))
            }
    }
    static Export(raw) {
        this.Require()
        r := this.Region(raw)
        if !FileExist(this.FramePath)
            throw Error("Capture Roblox before exporting an image region.")
        path := FileSelect("S16", A_ScriptDir "\detection.png", "Save detection image", "PNG image (*.png)")
        if path == ""
            return Map("cancelled", 1)
        if !RegExMatch(path, "i)\.png$")
            path .= ".png"
        token := Gdip_Startup(), bitmap := 0, crop := 0
        try {
            bitmap := Gdip_CreateBitmapFromFile(this.FramePath)
            if !bitmap
                throw Error("Could not open the developer capture.")
            crop := Gdip_CloneBitmapArea(bitmap, r["x"], r["y"], r["width"], r["height"])
            if !crop || Gdip_SaveBitmapToFile(crop, path) != 0
                throw Error("Could not save the selected PNG region.")
            return Map("saved", 1)
        } finally {
            if crop
                Gdip_DisposeImage(crop)
            if bitmap
                Gdip_DisposeImage(bitmap)
            Gdip_Shutdown(token)
        }
    }
}
