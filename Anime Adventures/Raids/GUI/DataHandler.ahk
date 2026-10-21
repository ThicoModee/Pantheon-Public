#Requires AutoHotkey v2.0
#Include gui.ahk

RegG := "HKEY_CURRENT_USER\Software\Pantheon"
global Reg := "HKEY_CURRENT_USER\Software\Pantheon\Raids"

GUILoad() {
    global

    ; Binds
    resizeBind := RegRead(RegG, "resizeBind")
    startBind := RegRead(RegG, "startBind")
    stopBind := RegRead(RegG, "stopBind")
    pauseBind := RegRead(RegG, "pauseBind")

    ; Checkboxes
    WebhookE := RegRead(RegG, "WebhookE")
    DCWebhookE := RegRead(RegG, "DCWebhookE")
    SOWebhookE := RegRead(Reg, "SOWebhookE")
    UpgradePriorityE := RegRead(Reg, "UpgradePriorityE")
    PingE := RegRead(RegG, "PingE")
    DCPingE := RegRead(RegG, "DCPingE")
    SOPingE := RegRead(Reg, "SOPingE")
    RichPresenceE := RegRead(RegG, "RichPresenceE", "1")
    RegWrite(RichPresenceE, "REG_SZ", "HKEY_CURRENT_USER\Software\Pantheon\discordRPCState", "Enabled")
    StatWebsiteE := RegRead(RegG, "StatWebsiteE")
    DEBUG := RegRead(RegG, "DEBUG")

    ; Inputs
    PServerURL := RegRead(RegG, "PServerURL")
    webhookURL := RegRead(RegG, "webhookURL")
    UserID := RegRead(RegG, "UserID")
    PlacementSpeed := RegRead(Reg, "PlacementSpeed")

    ; Dropdowns
    PlacementLogicFM := RegRead(Reg, "PlacementLogicFM")
    PathMappingFM := RegRead(Reg, "PathMappingFM")
    RaidMapFM := RegRead(Reg, "RaidMapFM")
    RaidStageFM := RegRead(Reg, "RaidStageFM")

    ; Units
    for i, v in [1, 2, 3, 4, 5, 6] {
        UnitEnabled.Set(i, RegRead(Reg, "Unit" . i . "Enabled"))
        placementFM.Set(i, RegRead(Reg, "placementFM" . i))
        UpgFM.Set(i, RegRead(Reg, "UpgPrioFM" . i))
        UpgPrioFM.Set(i, RegRead(Reg, "UpgFM" . i))
        TypeFM.Set(i, RegRead(Reg, "typeFM" . i))
        CurseContents.Set(i, RegRead(Reg, "CurseContents" . i))
    }

}

GUISave() {
    ; Binds
    RegWrite(resizeBind, "REG_SZ", RegG, "resizeBind")
    RegWrite(startBind, "REG_SZ", RegG, "startBind")
    RegWrite(stopBind, "REG_SZ", RegG, "stopBind")
    RegWrite(pauseBind, "REG_SZ", RegG, "pauseBind")

    ; Checkboxes
    RegWrite(WebhookCheckbox.Value, "REG_SZ", RegG, "WebhookE")
    RegWrite(DCWebhookCheckbox.Value, "REG_SZ", RegG, "DCWebhookE")
    RegWrite(SOWebhookCheckbox.Value, "REG_SZ", Reg, "SOWebhookE")
    RegWrite(UPCheckbox.Value, "REG_SZ", Reg, "UpgradePriorityE")
    RegWrite(PingCheckbox.Value, "REG_SZ", RegG, "PingE")
    RegWrite(DCPingCheckbox.Value, "REG_SZ", RegG, "DCPingE")
    RegWrite(SOPingCheckbox.Value, "REG_SZ", Reg, "SOPingE")
    RegWrite(RPCCheckbox.Value, "REG_SZ", RegG, "RichPresenceE")
    RegWrite(RPCCheckbox.Value, "REG_SZ", "HKEY_CURRENT_USER\Software\Pantheon\discordRPCState", "Enabled")
    RegWrite(StatWCheckbox.Value, "REG_SZ", RegG, "StatWebsiteE")
    RegWrite(DebugCheckbox.Value, "REG_SZ", RegG, "DEBUG")

    ; Inputs
    RegWrite(PServerInput.Text, "REG_SZ", RegG, "PServerURL")
    RegWrite(WebhookInput.Text, "REG_SZ", RegG, "WebhookURL")
    RegWrite(UserIDInput.Text, "REG_SZ", RegG, "UserID")
    RegWrite(PSInput.Text, "REG_SZ", Reg, "PlacementSpeed")

    ; Dropdowns
    RegWrite(PLDDL.Value, "REG_SZ", Reg, "PlacementLogicFM")
    RegWrite(PathMappingDDL.Value, "REG_SZ", Reg, "PathMappingFM")
    RegWrite(SelectedMap.Value, "REG_SZ", Reg, "RaidMapFM")
    RegWrite(SelectedStage.Value, "REG_SZ", Reg, "RaidStageFM")

    ; Units
    for i, v in [1, 2, 3, 4, 5, 6] {
        RegWrite(unitCheckbox.Get(i).Value, "REG_SZ", Reg, "Unit" . i . "Enabled")
        RegWrite(PlacementDDL.Get(i).Value, "REG_SZ", Reg, "placementFM" . i)
        RegWrite(UpgPrioDDL.Get(i).Value, "REG_SZ", Reg, "UpgFM" . i)
        RegWrite(UpgDDL.Get(i).Value, "REG_SZ", Reg, "UpgPrioFM" . i)
        RegWrite(TypeDDL.Get(i).Value, "REG_SZ", Reg, "typeFM" . i)
        RegWrite(CurseInput.Get(i).Text, "REG_SZ", Reg, "CurseContents" . i)
    }

    ; Update values
    Sleep 50
    GUILoad()
}

StatLoad() {
    global

    ; Runtime
    TotalRuntime := RegRead(Reg, "TotalRuntime")
    RuntimeText := RegRead(Reg, "RuntimeText")
    RuntimeTextSession := RegRead(Reg, "RuntimeTextSession")

    ; Wins
    winsTotal := RegRead(Reg, "TotalWins")
    winsSessionText := RegRead(Reg, "winsSession")

    ; Losses
    lossesTotal := RegRead(Reg, "TotalLosses")
    lossesSessionText := RegRead(Reg, "lossesSession")

    ; Attempts
    attemptsTotal := RegRead(Reg, "TotalAttempts")
    attemptsSessionText := RegRead(Reg, "attemptsSession")

    ; Disconnections
    disconnectionsTotal := RegRead(Reg, "TotalDisconnections")
    disconnectionsSessionText := RegRead(Reg, "disconnectionsSession")
}

StatSave() {
    ; Runtime
    RegWrite(totalRuntimeWithSession, "REG_SZ", Reg, "TotalRuntime")
    RegWrite(RuntimeText, "REG_SZ", Reg, "RuntimeText")
    RegWrite(RuntimeTextSession, "REG_SZ", Reg, "RuntimeTextSession")

    ; Wins
    RegWrite(TotalWins, "REG_SZ", Reg, "TotalWins")
    RegWrite(winsSession, "REG_SZ", Reg, "winsSession")

    ; Losses
    RegWrite(TotalLosses, "REG_SZ", Reg, "TotalLosses")
    RegWrite(lossesSession, "REG_SZ", Reg, "lossesSession")

    ; Attempts
    RegWrite(TotalAttempts, "REG_SZ", Reg, "TotalAttempts")
    RegWrite(attemptsSession, "REG_SZ", Reg, "attemptsSession")

    ; Disconnections
    RegWrite(TotalDisconnections, "REG_SZ", Reg, "TotalDisconnections")
    RegWrite(disconnectionsSession, "REG_SZ", Reg, "disconnectionsSession")
}
