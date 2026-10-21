#Requires AutoHotkey v2.0

#Include DataHandler.ahk
#Include Main.ahk
#Include Units.ahk
#Include Status.ahk
#Include Webhooks.ahk

#Include ..\..\..
#Include Lib\GUI\!CreateImageButton.ahk
#Include Lib\GUI\!WinDarkUI - Main.ahk
#Include Lib\GUI\!GuiEnchancerKit.ahk
#Include Lib\GUI\!DarkStyleMsgBox.ahk

#DllLoad "Gdiplus.dll"

Font := "Segoe UI"
FontSize := 9
PantheonIcon := "..\..\Lib\Images\PantheonIcon.ico"
TraySetIcon(PantheonIcon, , true)

; DEFAULTS
global resizeBind := "F1"
global startBind := "F2"
global stopBind := "F3"
global pauseBind := "F4"
global WebhookE := 0, SendChatE := 0, UpgradePriorityE := 0, PingE := 0, DCPingE := 0, SOPingE := 0, DCWebhookE := 0,
    SOWebhookE := 0, RichPresenceE := 0, StatWebsiteE := 0
global chatContents := "", WebhookURL := "", PServerURL := "", UserID := ""
global Unit1Enabled := 0, Unit2Enabled := 0, Unit3Enabled := 0, Unit4Enabled := 0, Unit5Enabled := 0, Unit6Enabled := 0
global placementFM1 := 1, placementFM2 := 1, placementFM3 := 1, placementFM4 := 1, placementFM5 := 1, placementFM6 := 1
global UpgFM1 := 1, UpgFM2 := 2, UpgFM3 := 3, UpgFM4 := 4, UpgFM5 := 5, UpgFM6 := 6
global typeFM1 := 1, typeFM2 := 1, typeFM3 := 1, typeFM4 := 1, typeFM5 := 1, typeFM6 := 1 ; TYPES: DPS=1 Ground=2 Hill=3 Buff=4 Farm=5
global modeFM := 1, PageFM := 1
global PlacementLogicFM := 1, PlacementSpeed := 2000
global statView := "Total"
global VersionText := "1.0.0"

try {
    GUILoad()
    global VersionText := RegRead("HKEY_CURRENT_USER\Software\Pantheon\Loader", "version_anime_adventures_challenges",
        "1.0.0"
    )
}

Hotkey(resizeBind, (*) => SetupMacro())
Hotkey(startBind, (*) => InitializeMacro())
Hotkey(stopBind, (*) => StopMacro())

SetWindowColor(hwnd, titleText?, titleBackground?, border?) {
    static DWMWA_BORDER_COLOR := 34
    static DWMWA_CAPTION_COLOR := 35
    static DWMWA_TEXT_COLOR := 36
    if (VerCompare(A_OSVersion, "10.0.22200") < 0)
        return ; MsgBox("This is supported starting with Windows 11 Build 22000.", "OS Version Not Supported.")
    if (border ?? 0)
        DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, border)
    if (titleBackground ?? 0)
        DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, titleBackground)
    if (titleText ?? 0)
        DwmSetWindowAttribute(hwnd, DWMWA_TEXT_COLOR, titleText)
    DwmSetWindowAttribute(hwnd?, dwAttribute?, pvAttribute?) => DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", hwnd,
        "UInt", dwAttribute, "Ptr*", &pvAttribute, "UInt", 4)
}

UseGDIP() {
    static GdipObject := 0
    if !IsObject(GdipObject) {
        GdipToken := 0
        SI := Buffer(24, 0)
        NumPut("UInt", 1, SI)
        if DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", &GdipToken, "Ptr", SI, "Ptr", 0, "UInt") {
            MsgBox("GDI+ could not be started!`n`nThe program will exit!", A_ThisFunc, 262160)
            ExitApp
        }
        GdipObject := { __Delete: UseGdipShutDown }
    }
    UseGdipShutDown(*) {
        DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", GdipToken)
    }
}
UseGDIP()

ButtonStyles := Map()

ButtonStyles["fake_for_group"] := [[0xFF171717, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 2],
[0xFF262626, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 2],
[0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 2],
[0xFF171717, 0xFF474747, 0xFFFFFFFF, 5, 0xFF202020, 2]]

ButtonStyles["divider"] := [[0xFF171717, 0xFF202020, 0xFFFFFFFF, 2, 0xFF202020, 2],
[0xFF262626, 0xFF202020, 0xFFFFFFFF, 2, 0xFF202020, 2],
[0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 2, 0xFF202020, 2],
[0xFF171717, 0xFF474747, 0xFFFFFFFF, 2, 0xFF202020, 2]]

ButtonStyles["holder"] := [[0xFF171717, 0xFF202020, 0xFFFFFFFF, 10, 0xFF202020, 2],
[0xFF262626, 0xFF202020, 0xFFFFFFFF, 10, 0xFF202020, 2],
[0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 10, 0xFF202020, 2],
[0xFF171717, 0xFF474747, 0xFFFFFFFF, 10, 0xFF202020, 2]]

ButtonStyles["reset"] := [[0xFF1b1b1b, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 2],
[0xFFFF4444, 0xFFCC0000, 0xFFFFFFFF, 5, 0xFFCC0000, 2],
[0xFFFF6666, 0xFFFF0000, 0xFFFFFFFF, 5, 0xFFFF0000, 2],
[0xFF1b1b1b, 0xFF474747, 0xFFFFFFFF, 5, 0xFF202020, 2]]

ButtonStyles["secondary"] := [[0xFF1b1b1b, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 2],
[0xFF44B244, 0xFF338833, 0xFFFFFFFF, 5, 0xFF338833, 2],
[0xFF66D166, 0xFF2D822D, 0xFFFFFFFF, 5, 0xFF2D822D, 2],
[0xFF1b1b1b, 0xFF474747, 0xFFFFFFFF, 5, 0xFF202020, 2]]

ButtonStyles["roblox"] := [[0x7e4141, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
[0x7e4141, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
[0x7e4141, 0xFF202020, 0xFFFFFFFF, 3, 0xFF202020, 2],
[0x7e4141, 0x7e4141, 0xFFFFFFFF, 3, 0xFF202020, 2]]

ButtonStyles["default"] := [[0xFF1b1b1b, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF262626, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF626262, 0xFF474747, 0xFFFFFFFF, 5, 0xFF474747, 1]]

mainGui := GuiExt("+AlwaysOnTop", "V" VersionText " / Pantheon Macro / Challenge")
MainGUI.SetFont("cWhite s" FontSize, Font)
mainGui.BackColor := 0x171717
CreateImageButton("SetDefGuiColor", 0x171717)

; Roblox Window
rblx := MaingUI.AddButton("x0 y0 w800 h600 0x100 Disabled", "")
CreateImageButton(rblx, 0, ButtonStyles["roblox"]*)
WinSetTransColor("0x7e4141 255", MainGUI)

; SETTINGS CONTAINER
STB1 := MaingUI.AddButton("x810 y0 w225 h640 0x100 Disabled", "")
CreateImageButton(STB1, 0, ButtonStyles["fake_for_group"]*)

;;;;;; Buttons ;;;;;;
; MAIN
mainButton := mainGui.AddButton("x54 y630 w130 h25", "Main")
mainButton.OnEvent("Click", (*) => TabCtrl.Choose("Main"))
CreateImageButton(mainButton, 0, ButtonStyles["default"]*)
; UNITS
unitButton := mainGui.AddButton("x195 y630 w130 h25", "Units")
unitButton.OnEvent("Click", (*) => TabCtrl.Choose("Units"))
CreateImageButton(unitButton, 0, ButtonStyles["default"]*)
; STATUS
statusButton := mainGui.AddButton("x336 y630 w130 h25", "Status")
statusButton.OnEvent("Click", (*) => TabCtrl.Choose("Status"))
CreateImageButton(statusButton, 0, ButtonStyles["default"]*)
; WEBHOOK
webhookButton := mainGui.AddButton("x477 y630 w130 h25", "Webhooks")
webhookButton.OnEvent("Click", (*) => TabCtrl.Choose("Webhooks"))
CreateImageButton(webhookButton, 0, ButtonStyles["default"]*)

tabArr := ["Main", "Units", "Status", "Webhooks"]
(TabCtrl := mainGui.Add("Tab", "x0 y0 w0 h0 -Wrap -Buttons -Theme", TabArr)).OnEvent("Change", (*) => TabCtrl.Focus())
SGW := SysGet(SM_CXMENUCHECK := 71)
SGH := SysGet(SM_CYMENUCHECK := 72)

TabCtrl.UseTab("Main")
MainTab()

TabCtrl.UseTab("Units")
UnitsTab()

TabCtrl.UseTab("Status")
StatusTab()

TabCtrl.UseTab("Webhooks")
WebhooksTab()

SetWindowAttribute(MainGUI)
SetWindowTheme(MainGUI)
SetWindowColor(MainGUI.Hwnd, 0xFFFFFFFF, 0x171717, 0xFF202020)
mainGui.Show("w1047 h677")

FetchPos()

RobloxPos() {
    mainGui.GetPos(&bX, &bY, ,)
    WinMove(bX, bY, 800, 600)
}

FetchPos() {
    mainGui.GetPos(&bX, &bY, ,)
    global deltaX := bX
    global deltaY := bY
}

global unitUpgradePrioritydropDowns := [UPGDDL1, UPGDDL2, UPGDDL3, UPGDDL4, UPGDDL5, UPGDDL6]

DropDownListWorker(Element, List, DispT, *) {
    DispT.Text := List[Element.Value]

    if DispT.Text == "Manual" {
        MsgBox("Manual is not available for this gamemode", "Error")
        Element.Value := 1
        DispT.Text := List[1]
    }

    CreateImageButton(DispT, 0, ButtonStyles["fake_for_group"]*)
    GUISave()
}

mainGui.OnEvent('Close', (*) => ExitApp())

try {
    GUILoad()
}
