#Requires AutoHotkey v2.0

#Include %A_LineFile%\..\framework\Packages.ahk
#Include %A_LineFile%\..\Placements.ahk

class GameMount {
    static Host := 0
    static Hwnd := 0
    static Original := 0
    static Rect := Map("x", 0, "y", 0, "width", 800, "height", 600, "visible", 0)
    static Enabled := false
    static Hidden := false
    static Capturing := false

    static Initialize(host) {
        this.Host := host
    }
    static Layout(rect) {
        for name in ["x", "y", "width", "height"]
            if !(rect[name] is Integer) || Abs(rect[name]) > 16000
                throw ValueError("Invalid game panel bounds.")
        ProfileStore.Int(rect["visible"], 0, 1, "Game panel visibility")
        this.Rect := rect
        this.Refresh()
        return Map("mounted", this.Hwnd && !this.Hidden ? 1 : 0)
    }
    static Refresh() {
        if this.Capturing
            return
        if this.Hwnd && !DllCall("IsWindow", "ptr", this.Hwnd)
            this.Hwnd := 0, this.Original := 0
        if !this.Enabled
            return
        if !this.Hwnd {
            if hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
                this.Attach(hwnd)
            else
                return
        }
        foreground := DllCall("GetForegroundWindow", "ptr")
        exposed := foreground == this.Host.Hwnd || foreground == this.Hwnd
        this.Host.GetClientPos(&left, &top, &width, &height)
        r := this.Rect
        visible := r["visible"] && exposed && WinGetMinMax("ahk_id " this.Host.Hwnd) != -1
            && r["x"] >= 0 && r["y"] >= 48 && r["x"] + 800 <= width && r["y"] + 600 <= height
        if !visible {
            if DllCall("GetWindowLongPtr", "ptr", this.Hwnd, "int", -20, "ptr") & 8
                DllCall("SetWindowPos", "ptr", this.Hwnd, "ptr", -2, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x13)
            if !exposed {
                if this.Hidden
                    WinShow("ahk_id " this.Hwnd)
                this.Hidden := false
            } else if !this.Hidden {
                WinHide("ahk_id " this.Hwnd)
                this.Hidden := true
            }
            return
        }
        if !DllCall("SetWindowPos", "ptr", this.Hwnd, "ptr", -1, "int", left+r["x"], "int", top+r["y"], "int", 800, "int", 600, "uint", 0x50)
            throw OSError(A_LastError)
        this.Hidden := false
    }
    static Enable() {
        this.Enabled := true
        this.Refresh()
        return Map("mounted", this.Hwnd && !this.Hidden ? 1 : 0)
    }
    static Attach(hwnd) {
        if this.Hwnd == hwnd
            return
        if this.Hwnd
            this.Detach()
        if !DllCall("IsWindow", "ptr", hwnd)
            throw Error("Roblox is no longer open.")
        style := WinGetStyle("ahk_id " hwnd)
        if style & 0x40000000
            throw Error("Unpin Roblox in the other macro before opening it here.")
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        this.Original := Map("style", style, "exStyle", WinGetExStyle("ahk_id " hwnd), "x", x, "y", y, "w", w, "h", h,
            "visible", DllCall("IsWindowVisible", "ptr", hwnd), "state", WinGetMinMax("ahk_id " hwnd))
        this.Hwnd := hwnd
        try {
            DllCall("SetWindowLongPtr", "ptr", hwnd, "int", -16, "ptr", (style & ~0x40CF0000) | 0x90000000, "ptr")
            DllCall("SetWindowLongPtr", "ptr", hwnd, "int", -20, "ptr", (this.Original["exStyle"] & ~0x08000080) | 0x40000, "ptr")
            DllCall("SetWindowPos", "ptr", hwnd, "ptr", -1, "int", x, "int", y, "int", 800, "int", 600, "uint", 0x30)
            this.Enabled := true
        } catch Error as err {
            this.Detach()
            throw Error("Roblox could not be pinned. " err.Message)
        }
    }
    static Focus() {
        if !this.Hwnd
            throw Error("Open Roblox first.")
        WinShow("ahk_id " this.Hwnd)
        WinActivate("ahk_id " this.Hwnd)
        this.Hidden := false
    }
    static Detach() {
        hwnd := this.Hwnd, original := this.Original
        if hwnd && original && DllCall("IsWindow", "ptr", hwnd) {
            DllCall("SetWindowLongPtr", "ptr", hwnd, "int", -16, "ptr", original["style"], "ptr")
            DllCall("SetWindowLongPtr", "ptr", hwnd, "int", -20, "ptr", original["exStyle"] & ~8, "ptr")
            if !DllCall("SetWindowPos", "ptr", hwnd, "ptr", -2, "int", original["x"], "int", original["y"], "int", original["w"], "int", original["h"], "uint", 0x30)
                throw OSError(A_LastError)
            WinShow("ahk_id " hwnd)
            if original["state"] == -1
                WinMinimize("ahk_id " hwnd)
            else if original["state"] == 1
                WinMaximize("ahk_id " hwnd)
            if !DllCall("SetWindowPos", "ptr", hwnd, "ptr", -2, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x13)
                throw OSError(A_LastError)
        }
        this.Hwnd := 0, this.Original := 0, this.Hidden := false
    }
    static Release() {
        this.Enabled := false
        this.Detach()
        return Map("mounted", 0)
    }
}

class HubEngine {
    static StartedAt := 0
    static Elapsed := 0
    static Pid := 0
    static Mode := ""
    static Folder := ""
    static Token := ""
    static Host := 0

    static State() {
        if !this.Pid || !ProcessExist(this.Pid)
            return "stopped"
        return IniRead(this.Folder "\state.ini", "Engine", "State", "initializing")
    }
    static Busy() => this.State() != "stopped" && this.State() != "ready" && this.State() != "error"

    static Start(id) {
        id := MacroHub.Mode(id)
        if !GameMount.Hwnd
            GameMount.Enable()
        if !GameMount.Rect["visible"]
            throw Error("Open the macro dashboard before starting.")
        if this.State() == "running" || this.State() == "paused"
            throw Error("Stop the current run before starting another.")
        this.Stop()
        plan := MacroHub.LaunchPlan(id)
        guid := Buffer(16)
        DllCall("ole32\CoCreateGuid", "ptr", guid)
        this.Token := ""
        loop 16
            this.Token .= Format("{:02x}", NumGet(guid, A_Index - 1, "uchar"))
        this.Folder := A_ScriptDir "\data\sessions\" this.Token
        DirCreate(this.Folder)
        this.Mode := id
        ProfileStore.WriteJson(this.Folder "\framework.json", MacroPackages.Load(id)["definition"])
        ProfileStore.WriteJson(this.Folder "\settings-values.json", MacroPackages.Values(id))
        ProfileStore.WriteJson(this.Folder "\placements.json", PlacementStore.Load(id)["profile"])
        ProfileStore.WriteJson(this.Folder "\play-controls.json", PlayControls.Resolve(MacroPackages.Load(id)["definition"], MacroPackages.Values(id), PlayControls.Load()))
        cmd := plan["command"] ' --pantheon-hub ' this.Host.Hwnd ' ' this.Token ' "' this.Folder '" ' GameMount.Hwnd
        Run(cmd, plan["directory"], "Hide", &pid)
        this.Pid := pid
        ready := false
        started := A_TickCount
        while A_TickCount - started < 12000 {
            if !ProcessExist(pid)
                throw Error("The " id " engine exited during initialization. See data/sessions for its error log.")
            if this.State() == "ready" {
                ready := true
                break
            }
            Sleep(50)
        }
        if !ready {
            this.Stop()
            throw Error("The " id " engine did not become ready.")
        }
        GameMount.Focus()
        this.Send("start")
        this.StartedAt := A_TickCount, this.Elapsed := 0
        MacroHub.Log(id " started.")
        return Map("state", "running")
    }
    static Send(action) {
        if !this.Pid || !ProcessExist(this.Pid)
            throw Error("No macro engine is active.")
        oldDetect := A_DetectHiddenWindows
        DetectHiddenWindows(true)
        try hwnd := WinExist("ahk_pid " this.Pid " ahk_class AutoHotkey")
        finally DetectHiddenWindows(oldDetect)
        if !hwnd
            throw Error("The macro engine is unavailable.")
        text := this.Token "|" action
        data := Buffer((StrLen(text) + 1) * 2)
        StrPut(text, data, "UTF-16")
        packet := Buffer(3 * A_PtrSize, 0)
        NumPut("ptr", 0x50414E54, packet, 0)
        NumPut("uint", data.Size, packet, A_PtrSize)
        NumPut("ptr", data.Ptr, packet, 2 * A_PtrSize)
        DetectHiddenWindows(true)
        try result := SendMessage(0x4A, this.Host.Hwnd, packet.Ptr, , "ahk_id " hwnd, , , , 2000)
        finally DetectHiddenWindows(oldDetect)
        if result != 1
            throw Error("The macro engine rejected the command.")
    }
    static Pause() {
        state := this.State()
        if state != "running" && state != "paused"
            throw Error("No macro is running.")
        this.Send("pause")
        return Map("state", state == "paused" ? "running" : "paused")
    }
    static Stop() {
        if this.StartedAt {
            this.Elapsed := Floor((A_TickCount - this.StartedAt) / 1000)
            this.StartedAt := 0
        }
        if this.Pid && ProcessExist(this.Pid) {
            try this.Send("exit")
            if ProcessWaitClose(this.Pid, 2) != 0
                ProcessClose(this.Pid)
        }
        this.Pid := 0
        if GameMount.Hwnd
            try ControlSend("{w up}{a up}{s up}{d up}{Space up}{Shift up}{Control up}{LButton up}{RButton up}", , "ahk_id " GameMount.Hwnd)
        return Map("state", "stopped")
    }
    static Snapshot() {
        if this.StartedAt && !this.Busy() {
            this.Elapsed := Floor((A_TickCount-this.StartedAt)/1000)
            this.StartedAt := 0
        }
        logs := []
        if this.Folder && FileExist(this.Folder "\log.txt") {
            text := FileRead(this.Folder "\log.txt", "UTF-8")
            lines := StrSplit(Trim(SubStr(text, -12000)), "`n", "`r")
            for line in lines
                if line != ""
                    logs.Push(line)
            while logs.Length > 20
                logs.RemoveAt(1)
        }
        active := this.Busy() ? 1 : 0
        seconds := this.StartedAt && active ? Floor((A_TickCount - this.StartedAt) / 1000) : this.Elapsed
        return Map("mode", this.Mode, "state", this.State(), "active", active, "logs", logs, "seconds", seconds,
            "wins", this.Folder ? Integer(IniRead(this.Folder "\state.ini", "Stats", "Wins", 0)) : 0,
            "losses", this.Folder ? Integer(IniRead(this.Folder "\state.ini", "Stats", "Losses", 0)) : 0)
    }
}
