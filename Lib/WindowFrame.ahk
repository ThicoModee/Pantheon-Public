#Requires AutoHotkey v2.0

class HubFrame {
    static Hwnd := 0
    static Initialize(guiObj) {
        this.Hwnd := guiObj.Hwnd
        OnMessage(0x83, ObjBindMethod(this, "Calculate"))
        OnMessage(0x24, ObjBindMethod(this, "MinMax"))
        try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.Hwnd, "uint", 34, "uint*", 0xFFFFFFFE, "uint", 4)
        margins := Buffer(16, 0)
        DllCall("dwmapi\DwmExtendFrameIntoClientArea", "ptr", this.Hwnd, "ptr", margins)
        DllCall("SetWindowPos", "ptr", this.Hwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x37)
    }
    static Calculate(wParam, lParam, msg, hwnd) {
        if hwnd == this.Hwnd && wParam
            return 0
    }
    static MinMax(wParam, lParam, msg, hwnd) {
        if hwnd != this.Hwnd
            return
        monitor := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")
        info := Buffer(40), NumPut("uint", 40, info)
        if !DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info)
            return
        NumPut("int", NumGet(info,28,"int")-NumGet(info,20,"int"), "int", NumGet(info,32,"int")-NumGet(info,24,"int"), lParam, 8)
        NumPut("int", NumGet(info,20,"int")-NumGet(info,4,"int"), "int", NumGet(info,24,"int")-NumGet(info,8,"int"), lParam, 16)
        NumPut("int", 1100, "int", 780, "int", 32000, "int", 32000, lParam, 24)
        return 0
    }
}
