#Requires AutoHotkey v2.0
#Include gui.ahk

WebhooksTab() {
    global PingCheckbox, DCPingCheckbox, WebhookCheckbox, SOPingCheckbox, DCWebhookCheckbox, SOWebhookCheckbox
    global WebhookInput, UserIDInput

    ; --- Box & Heading ---
    holder := MaingUI.AddButton("x820 y10 w205 h152 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)
    MainGUI.AddText("x824 y15 w197 Center", "Webhooks")

    WebhookCheckbox := MainGUI.AddCheckBox("x830 y40 h" SGH " w" SGW)
    WebhookCheckbox.Value := WebhookE
    WebhookCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y40", " Enabled")

    MainGUI.AddText("x830 y65 w193", "Webhook URL")
    BG := MainGUI.AddButton("x830 y85 w185 h25 Disabled")
    CreateImageButton(BG, 0, ButtonStyles["fake_for_group"]*)
    WebhookInput := MainGUI.AddEdit("x830 y85 w185 h25 Background1B1B1B", "")
    WebhookInput.Value := WebhookURL
    WebhookInput.OnEvent('Change', (*) => GUISave())
    WebhookInput.SetRounded(5)

    DCWebhookCheckbox := MainGUI.AddCheckBox("x830 y120 h" SGH " w" SGW)
    DCWebhookCheckbox.Value := DCWebhookE
    DCWebhookCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y120", " Disconnections")

    SOWebhookCheckbox := MainGUI.AddCheckBox("x830 y140 h" SGH " w" SGW)
    SOWebhookCheckbox.Value := SOWebhookE
    SOWebhookCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y140", " Stage Outcome")

    ; -Pings-
    holder := MaingUI.AddButton("x820 y178 w205 h152 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)

    MainGUI.AddText("x824 y183 w197 Center", "Pings")

    PingCheckbox := MainGUI.AddCheckBox("x830 y208 h" SGH " w" SGW)
    PingCheckbox.Value := PingE
    PingCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y208", " Enabled")

    MainGUI.AddText("x830 y233 w193" , "User ID")
    BG := MainGUI.AddButton("x830 y253 w185 h25 Disabled")
    CreateImageButton(BG, 0, ButtonStyles["fake_for_group"]*)
    UserIDInput := MainGUI.AddEdit("x830 y253 w185 h25", "")
    UserIDInput.Value := UserID
    UserIDInput.OnEvent('Change', (*) => GUISave())
    UserIDInput.SetRounded(5)

    DCPingCheckbox := MainGUI.AddCheckBox("x830 y290 h" SGH " w" SGW)
    DCPingCheckbox.Value := DCPingE
    DCPingCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y290", " Disconnections")

    SOPingCheckbox := MainGUI.AddCheckBox("x830 y310 h" SGH " w" SGW)
    SOPingCheckbox.Value := SOPingE
    SOPingCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y310", " Stage Outcome")

    WebhookTestButton := mainGui.AddButton("x858 y605 w130 h25", "Test Webhook")
    WebhookTestButton.OnEvent('Click', (*) => WebhookTest())
    CreateImageButton(WebhookTestButton, 0, ButtonStyles["secondary"]*)
}

WebhookTest() {
    discord.SendEmbed("Test")
}