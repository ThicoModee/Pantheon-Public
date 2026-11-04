#Requires AutoHotkey v2.0

#Include %A_LineFile%\..\..\vendor\FindText.ahk
#Include %A_LineFile%\..\..\vendor\Gdip_All.ahk



class RobloxFlowEnvironment {

    __New(hwnd, log, result := 0) {

        this.ResultCallback := result
        this.Hwnd := hwnd, this.Log := log, this.Held := Map(), this.PausedKeys := []

    }

    Check() {

        if !DllCall("IsWindow", "ptr", this.Hwnd) || WinGetProcessName("ahk_id " this.Hwnd) != "RobloxPlayerBeta.exe"

            throw Error("The workflow's Roblox client is unavailable.")

        if !WinActive("ahk_id " this.Hwnd)

            throw Error("Workflow stopped because Roblox lost focus.")

        WinGetClientPos(, , &w, &h, "ahk_id " this.Hwnd)

        if w != 800 || h != 600

            throw Error("The workflow requires an 800 x 600 Roblox client.")

    }

    Find(target) {

        this.Check()

        if target["kind"] == "point"

            return Map("x", target["x"]+target["offsetX"], "y", target["y"]+target["offsetY"])

        WinGetClientPos(&left, &top, , , "ahk_id " this.Hwnd)

        error1 := target["error1"] ? target["error1"]/100 : 0.000000001

        error0 := target["error0"] ? target["error0"]/100 : 0.000000001

        if !FindText(&x, &y, left+target["x"], top+target["y"], left+target["x"]+target["width"]-1,

            top+target["y"]+target["height"]-1, error1, error0, target["pattern"])

            return 0

        return Map("x", x-left+target["offsetX"], "y", y-top+target["offsetY"])

    }

    Move(x, y) {

        this.Check()

        FlowSchema.Int(x, 0, 799, "Mouse X"), FlowSchema.Int(y, 0, 599, "Mouse Y")

        WinGetClientPos(&left, &top, , , "ahk_id " this.Hwnd)

        previous := A_CoordModeMouse

        CoordMode("Mouse", "Screen")

        previousMode := A_SendMode
        try {
            SendMode("Event")
            MouseMove(left+x, top+y)
            this.Check()
        } finally {
            SendMode(previousMode)
            CoordMode("Mouse", previous)
        }

    }

    Click(x, y, button := "Left") {

        if button != "Left" && button != "Right"

            throw Error("Unsupported mouse button.")

        previousMode := A_SendMode, previousCoordinates := A_CoordModeMouse
        key := button == "Left" ? "LButton" : "RButton"
        try {
            SendMode("Event")
            CoordMode("Mouse", "Screen")
            this.Move(x, y)
            nudge := x < 799 ? 1 : -1
            MouseMove(nudge, 0, , "R")
            this.Check()
            this.Held[key] := true
            MouseClick(button, -nudge, 0, , , , "R")
            this.Sleep(50)
            this.Check()
        } finally {
            try this.Key(key, false)
            finally {
                SendMode(previousMode)
                CoordMode("Mouse", previousCoordinates)
            }
        }

    }

    Scroll(direction, ticks) {

        this.Check()

        if direction != "Up" && direction != "Down"

            throw Error("Unsupported scroll direction.")

        FlowSchema.Int(ticks, 1, 10, "Scroll amount")

        previous := A_CoordModeMouse

        CoordMode("Mouse", "Screen")

        try {

            MouseGetPos(&x, &y)

            WinGetClientPos(&left, &top, &w, &h, "ahk_id " this.Hwnd)

            if x < left || x >= left+w || y < top || y >= top+h

                throw Error("Move the mouse inside Roblox before scrolling.")

            MouseClick("Wheel" direction, , , ticks)

        } finally CoordMode("Mouse", previous)

    }

    Key(key, down) {

        if down {

            this.Check()

            this.Held[key] := true

            this.SendKey(key, true)

        } else if this.Held.Has(key) {

            this.SendKey(key, false)

            if DllCall("IsWindow", "ptr", this.Hwnd)

                try ControlSend("{" key " up}", , "ahk_id " this.Hwnd)

            this.Held.Delete(key)

        }

    }

    SendKey(key, down) {
        text := "{" key (down ? " down}" : " up}")
        if key == "LButton" || key == "RButton"
            SendEvent(text)
        else
            SendInput(text)
    }

    Progress(rect) {
        this.Check()
        WinGetClientPos(&left, &top, , , "ahk_id " this.Hwnd)
        token := Gdip_Startup(), bitmap := 0, locked := false, result := []
        try {
            bitmap := Gdip_BitmapFromScreen((left+rect["x"]) "|" (top+rect["y"]) "|" rect["width"] "|" rect["height"], 0x40CC0020)
            if bitmap <= 0 || Gdip_LockBits(bitmap, 0, 0, rect["width"], rect["height"], &stride, &scan, &data, 1) != 0
                throw FlowImageError("Could not capture the upgrade progress region.")
            locked := true
            strideX := Max(1, Ceil(rect["width"]/64)), strideY := Max(1, Ceil(rect["height"]/16))
            loop Ceil(rect["height"]/strideY) {
                y := (A_Index-1)*strideY
                this.Check()
                loop Ceil(rect["width"]/strideX)
                    result.Push(NumGet(scan+y*stride+((A_Index-1)*strideX)*4, "uint") & 0xFFFFFF)
            }
            return result
        } finally {
            if locked
                Gdip_UnlockBits(bitmap, &data)
            if bitmap > 0
                Gdip_DisposeImage(bitmap)
            Gdip_Shutdown(token)
        }
    }

    Sleep(milliseconds) => Sleep(milliseconds)

    Result(won) {
        if this.ResultCallback
            this.ResultCallback.Call(won)
    }

    Trace(flow, step, action) => this.Log.Call("Workflow " flow " / " step " · " action)

    Suspend() {

        this.PausedKeys := []

        for key in this.Held

            this.PausedKeys.Push(key)

        this.Release()

    }

    Resume() {

        try {

            for key in this.PausedKeys

                this.Key(key, true)

        } catch Error as err {

            this.Release()

            throw err

        } finally this.PausedKeys := []

    }

    Release() {

        for key in this.Held

            try {

                this.SendKey(key, false)

                if DllCall("IsWindow", "ptr", this.Hwnd)

                    ControlSend("{" key " up}", , "ahk_id " this.Hwnd)

            }

        this.Held := Map()

    }

}
