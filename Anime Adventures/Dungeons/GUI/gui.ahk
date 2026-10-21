#Requires AutoHotkey v2.0

#Include DataHandler.ahk
#Include Main.ahk
#Include Units.ahk
#Include Status.ahk
#Include Webhooks.ahk

#Include ..\..\..\
#Include Lib\GUI\!CreateImageButton.ahk
#Include Lib\GUI\!WinDarkUI - Main.ahk
#Include Lib\GUI\!GuiEnchancerKit.ahk
#Include Lib\GUI\!DarkStyleMsgBox.ahk
#Include Lib\GUI\GuiCtrlTips.ahk

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
global WebhookE := 0, SendChatE := 0, PartyConnectE := 0, UpgradePriorityE := 0, PingE := 0, DCPingE := 0, SOPingE := 0, RandomPrioE := 0, RandomPrioShopE := 0, DCWebhookE := 0, SOWebhookE := 0, RichPresenceE := 0, StatWebsiteE := 0
global chatContents := "", WebhookURL := "", PServerURL := "", UserID := ""

global UnitEnabled := Map()
UnitEnabled.Default := 0

global placementFM := Map()
placementFM.Default := 1

global UpgPrioFM := Map()
UpgPrioFM.Set(1, 1), UpgPrioFM.Set(2, 2), UpgPrioFM.Set(3, 3), UpgPrioFM.Set(4, 4), UpgPrioFM.Set(5, 5), UpgPrioFM.Set(6, 6)

global UpgFM := Map()
UpgFM.Default := 1

global TypeFM := Map()
TypeFM.Default := 1 ; TYPES: DPS=1 Ground=2 Hill=3 Buff=4 Farm=5

global CurseContents := Map()
CurseContents.Default := ""

global FloorFM := Map()
FloorFM.Set(1, 1), FloorFM.Set(2, 2), FloorFM.Set(3, 3), FloorFM.Set(4, 4), FloorFM.Set(5, 5), FloorFM.Set(6, 6)

global ShopItemEnabled := Map()
ShopItemEnabled.Default := 2

global PlacementLogicFM := 1, PlacementSpeed := 2000
global PathMappingFM := 1
global SelectedFloor := []
global statView := "Total"
global DEBUG := 0
global VersionText := "1.0.0"

try {
    GUILoad()
    global VersionText := RegRead("HKEY_CURRENT_USER\Software\Pantheon\Loader",
        "version_anime_adventures_dungeons_tester",
        "1.0.0")
}

Hotkey(resizeBind, (*) => SetupMacro())
Hotkey(startBind, (*) => InitializeMacro())
Hotkey(stopBind, (*) => StopMacro())
Hotkey(pauseBind, (*) => PauseMacro())

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

ButtonStyles["fake_for_group"] := [[0xFF171717, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF262626, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF171717, 0xFF474747, 0xFFFFFFFF, 5, 0xFF202020, 1]]

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

ButtonStyles["popup"] := [[0x1d7d18, 0x1d7d18, 0xFFFFFFFF, 5, 0x1d7d18, 2],
[0x1d7d18, 0x1d7d18, 0xFFFFFFFF, 5, 0x1d7d18, 2],
[0x1d7d18, 0x1d7d18, 0xFFFFFFFF, 5, 0x1d7d18, 2],
[0x1d7d18, 0x1d7d18, 0xFFFFFFFF, 5, 0x1d7d18, 2]]

ButtonStyles["popupError"] := [[0x7d181d, 0x7d181d, 0xFFFFFFFF, 5, 0x7d181d, 2],
[0x7d181d, 0x7d181d, 0xFFFFFFFF, 5, 0x7d181d, 2],
[0x7d181d, 0x7d181d, 0xFFFFFFFF, 5, 0x7d181d, 2],
[0x7d181d, 0x7d181d, 0xFFFFFFFF, 5, 0x7d181d, 2]]

ButtonStyles["default"] := [[0xFF1b1b1b, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF262626, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF2F2F2F, 0xFF202020, 0xFFFFFFFF, 5, 0xFF202020, 1],
[0xFF626262, 0xFF474747, 0xFFFFFFFF, 5, 0xFF474747, 1]]

mainGui := GuiExt("+AlwaysOnTop", "V" VersionText " / Pantheon Macro / Dungeons")
MainGui.Tips := GuiCtrlTips(MainGui)
MainGui.Tips.SetBkColor(0x404040)
MainGui.Tips.SetTxColor(0xFFFFFF)
MainGUI.SetFont("cWhite s" FontSize, Font)
mainGui.BackColor := 0x171717
CreateImageButton("SetDefGuiColor", 0x171717)

; Roblox Window
rblx := mainGui.AddButton("x0 y0 w800 h600 Disabled", "")
CreateImageButton(rblx, 0, ButtonStyles["roblox"]*)
WinSetTransColor("0x7e4141", MainGUI)

; SETTINGS CONTAINER
STB1 := MaingUI.AddButton("x810 y0 w225 h640 Disabled", "")
CreateImageButton(STB1, 0, ButtonStyles["holder"]*)

;;;;;; Buttons ;;;;;;
; MAIN
mainButton := mainGui.AddButton("x76 y630 w150 h25", "Main")
mainButton.OnEvent("Click", (*) => TabCtrl.Choose("Main"))
CreateImageButton(mainButton, 0, ButtonStyles["default"]*)
; UNITS
unitButton := mainGui.AddButton("x242 y630 w150 h25", "Units")
unitButton.OnEvent("Click", (*) => TabCtrl.Choose("Units"))
CreateImageButton(unitButton, 0, ButtonStyles["default"]*)
; STATUS
statusButton := mainGui.AddButton("x408 y630 w150 h25", "Status")
statusButton.OnEvent("Click", (*) => TabCtrl.Choose("Status"))
CreateImageButton(statusButton, 0, ButtonStyles["default"]*)
; WEBHOOK
webhookButton := mainGui.AddButton("x574 y630 w150 h25", "Webhooks")
webhookButton.OnEvent("Click", (*) => TabCtrl.Choose("Webhooks"))
CreateImageButton(webhookButton, 0, ButtonStyles["default"]*)

; --- STATUS INDICATOR ---
StatusIndicatorH := mainGui.AddPicture("x1019 y650 w20 h20", "")

StatusIndicatorH.Value := 'HBITMAP: ' . DrawStatus(20, 0xFF5B55)

tabArr := ["Main", "Units", "Status", "Webhooks", "Party", "UnitsTab2", "MainTab2"]
(TabCtrl := mainGui.Add("Tab", "x0 y0 w0 h0", TabArr)).OnEvent("Change", (*) => TabCtrl.Focus())
SGW := SysGet(SM_CXMENUCHECK := 71)
SGH := SysGet(SM_CYMENUCHECK := 72)
CurrentPopup := ""

TabCtrl.UseTab("Main")
MainTab()

TabCtrl.UseTab("Units")
UnitsTab()
for i, v in [1, 2, 3, 4, 5, 6] {
    if TypeFM.Get(i) == 4 {
        SPACurse.Get(i).Opt("-Hidden")
        SPABG.Get(i).Opt("-Hidden")
        CurseInput.Get(i).Opt("-Hidden")
    }
}

TabCtrl.UseTab("Status")
StatusTab()

TabCtrl.UseTab("Webhooks")
WebhooksTab()

;TabCtrl.UseTab("Party")
;PartyTab()

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

global unitUpgradePrioritydropDowns := [UpgPrioDDL.Get(1), UpgPrioDDL.Get(2), UpgPrioDDL.Get(3), UpgPrioDDL.Get(4), UpgPrioDDL.Get(5), UpgPrioDDL.Get(6)]

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

FloorListWorker(Element, List, DispT, *) {
    DispT.Text := List[Element.Value]

    global SelectedFloor := []
    global SelectedShop := []

    for i, v in FloorPriority {
        SelectedFloor.Push(StrLower(StrReplace(v.Text, " ", "_")))
    }

    for i, v in ShopPriority {
        SelectedShop.Push(StrLower(StrReplace(v.Text, " ", "_")))
    }

    CreateImageButton(DispT, 0, ButtonStyles["fake_for_group"]*)
    GUISave()
}

ShopItemWorker(value, item) {
    ShopItemEnabled.Get(value) == 1 ? ShopItemEnabled.Set(value, 2) : ShopItemEnabled.Set(value, 1)
    ShopPriority.Get(value).Value := ItemImages[item][ShopItemEnabled.Get(value)]
    GUISave()
}

ChangeType(num, Element, List, DispT, *) {
    global SPACurse, SPABG, CurseInput
    DropDownListWorker(Element, List, DispT)

    if (DispT.Text == "Buff") {
        SPACurse.Get(num).Opt("-Hidden")
        SPABG.Get(num).Opt("-Hidden")
        CurseInput.Get(num).Opt("-Hidden")
    } else {
        SPACurse.Get(num).Opt("+Hidden")
        SPABG.Get(num).Opt("+Hidden")
        CurseInput.Get(num).Opt("+Hidden")
    }
}

DrawStatus(size, color, alpha := 255) {
    #DllLoad gdiplus
    static pixFormat := PixelFormat32bppARGB := 0x26200A
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0), NumPut('UInt', 1, si, 0)
    gdiplus := (fn, params*) => DllCall('gdiplus\' . fn, params*)
    gdiplus('GdiplusStartup', 'Ptr*', &pToken := 0, 'Ptr', si, 'Ptr', 0)
    gdiplus('GdipCreateBitmapFromScan0', 'int', size, 'int', size, 'int', 0, 'int', pixFormat, 'Ptr', 0, 'Ptr*', &
        pBitmap := 0)
    gdiplus('GdipGetImageGraphicsContext', 'Ptr', pBitmap, 'Ptr*', &pGraphics := 0)
    gdiplus('GdipSetSmoothingMode', 'Ptr', pGraphics, 'Int', 4) ; antialias
    gdiplus('GdipCreateSolidFill', 'UInt', alpha << 24 | color, 'Ptr*', &pBrush := 0)
    gdiplus('GdipFillEllipse', 'Ptr', pGraphics, 'Ptr', pBrush, 'Float', 0, 'Float', 0, 'Float', size - 1, 'Float',
        size - 1)
    gdiplus('GdipCreateHBITMAPFromBitmap', 'Ptr', pBitmap, 'Ptr*', &hBitmap := 0, 'int', 0xFFFFFFFF)

    gdiplus('GdipDeleteBrush', 'Ptr', pBrush)
    gdiplus('GdipDeleteGraphics', 'Ptr', pGraphics)
    gdiplus('GdipDisposeImage', 'Ptr', pBitmap)
    gdiplus('GdiplusShutdown', 'Ptr', pToken)
    return hBitmap
}

ShowPopup(Message := "", IsError := False) {
    global CurrentPopup
    TabCtrl.UseTab()

    if (CurrentPopup) {
        CurrentPopup.Visible := False
    }

    CurrentPopup := mainGui.Add("Button", "x0 y0 w200 h25", Message)
    CurrentPopup.Opt("+Disabled")
    IsError ? CreateImageButton(CurrentPopup, 0, ButtonStyles["popupError"]*) : CreateImageButton(CurrentPopup, 0,
        ButtonStyles["popup"]*)

    mainGui.GetClientPos(&MainGuiX, &MainGuiY, &MainGuiWidth, &MainGuiHeight)

    PopupWidth := 200
    PopupHeight := 25
    InitialX := MainGuiWidth - PopupWidth - 24
    initialY := MainGuiHeight

    CurrentPopup.Move(InitialX, InitialY)

    FinalY := MainGuiHeight - PopupHeight - 6

    loop 5 {
        CurrentPopup.GetPos(, &CurrentY)
        NewY := CurrentY - 6
        CurrentPopup.Move(, NewY)
        Sleep 5
    }

    Sleep 2000

    loop 20 {
        CurrentPopup.GetPos(&PopupX, &PopupY)
        NewX := PopupX + 10
        CurrentPopup.Move(NewX)
        Sleep 20
    }

    CurrentPopup.Visible := False
}

mainGui.OnEvent('Close', (*) => ExitApp())

try {
    GUILoad()
}
