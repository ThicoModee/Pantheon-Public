#Requires AutoHotkey v2.0
#Include gui.ahk

RegG := "HKEY_CURRENT_USER\Software\Pantheon"
Reg := "HKEY_CURRENT_USER\Software\Pantheon\Contracts"

GUILoad() {
    ;global resizeBind, startBind, stopBind
    ;global chatContents, webhookURL, UserID, PlacementSpeed, ModeFM, PServerURL
    ;global WebhookE, SendChatE, UpgradePriorityE, PingE, DCPingE, SOPingE, DCWebhookE, SOWebhookE
    ;global Unit1Enabled, Unit2Enabled, Unit3Enabled, Unit4Enabled, Unit5Enabled, Unit6Enabled
    ;global placementFM1, placementFM2, placementFM3, placementFM4, placementFM5, placementFM6, PlacementLogicFM
    ;global UpgFM1, UpgFM2, UpgFM3, UpgFM4, UpgFM5, UpgFM6
    ;global typeFM1, typeFM2, typeFM3, typeFM4, typeFM5, typeFM6
    global

    ; Binds
    resizeBind := RegRead(RegG, "resizeBind")
    startBind := RegRead(RegG, "startBind")
    stopBind := RegRead(RegG, "stopBind")
    pauseBind := RegRead(RegG, "pauseBind")

    ; Checkboxes
    SendChatE := RegRead(RegG, "SendChatE")
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

    ; Inputs
    chatContents := RegRead(RegG, "chatContents")
    PServerURL := RegRead(RegG, "PServerURL")
    webhookURL := RegRead(RegG, "webhookURL")
    UserID := RegRead(RegG, "UserID")
    PlacementSpeed := RegRead(Reg, "PlacementSpeed")
    PlacementLogicFM := RegRead(Reg, "PlacementLogicFM")

    ; Dropdowns
    ModeFM := RegRead(Reg, "ModeFM")

    ; Units
    for i, v in [1, 2, 3, 4, 5, 6] {
        %"Unit" . i . "Enabled"% := RegRead(Reg, "Unit" . i . "Enabled")
        %"placementFM" . i% := RegRead(Reg, "placementFM" . i)
        %"UpgFm" . i% := RegRead(Reg, "UpgFM" . i)
        %"typeFM" . i% := RegRead(Reg, "typeFM" . i)
    }
}

GUISave() {
    ; Binds
    RegWrite(resizeBind, "REG_SZ", RegG, "resizeBind")
    RegWrite(startBind, "REG_SZ", RegG, "startBind")
    RegWrite(stopBind, "REG_SZ", RegG, "stopBind")
    RegWrite(pauseBind, "REG_SZ", RegG, "pauseBind")

    ; Checkboxes
    RegWrite(SCCheckbox.Value, "REG_SZ", RegG, "SendChatE")
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

    ; Inputs
    RegWrite(ChatInput.Text, "REG_SZ", RegG, "chatContents")
    RegWrite(PServerInput.Text, "REG_SZ", RegG, "PServerURL")
    RegWrite(WebhookInput.Text, "REG_SZ", RegG, "WebhookURL")
    RegWrite(UserIDInput.Text, "REG_SZ", RegG, "UserID")
    RegWrite(PSInput.Text, "REG_SZ", Reg, "PlacementSpeed")
    RegWrite(PLDDL.Value, "REG_SZ", Reg, "PlacementLogicFM")

    ; Dropdowns
    RegWrite(MatchmakeMode.Value, "REG_SZ", Reg, "ModeFM")

    ; Units
    for i, v in [1, 2, 3, 4, 5, 6] {
        RegWrite((%"Unit" . i . "Checkbox"%).Value, "REG_SZ", Reg, "Unit" . i . "Enabled")
        RegWrite((%"PMDDL" . i%).Value, "REG_SZ", Reg, "placementFM" . i)
        RegWrite((%"UPGDDL" . i%).Value, "REG_SZ", Reg, "UpgFM" . i)
        RegWrite((%"TypeDDL" . i%).Value, "REG_SZ", Reg, "typeFM" . i)
    }

    ; Update values
    Sleep 50
    GUILoad()
}

StatLoad() {
    global TotalRuntime, RuntimeText, RuntimeTextSession, starsTotal, starsSessionText, winsTotal, winsSessionText,
        lossesTotal, lossesSessionText, attemptsTotal, attemptsSessionText, disconnectionsTotal,
        disconnectionsSessionText

    ; Runtime
    TotalRuntime := RegRead(Reg, "TotalRuntime")
    RuntimeText := RegRead(Reg, "RuntimeText")
    RuntimeTextSession := RegRead(Reg, "RuntimeTextSession")

    ; Stars
    starsTotal := RegRead(Reg, "starsTotal")
    starsSessionText := RegRead(Reg, "starsSession")

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

    ; Stars
    RegWrite(TotalStarsEarned, "REG_SZ", Reg, "starsTotal")
    RegWrite(starsSession, "REG_SZ", Reg, "starsSession")

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
