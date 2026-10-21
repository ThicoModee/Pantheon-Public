#Requires AutoHotkey v2.0

#Include Winter.ahk

#Include ..\..
#Include Lib\Discord-Webhook-master\lib\WEBHOOK.ahk
#Include Lib\Gdip_All.ahk

;#Include %A_ScriptDir%\..\Lib\Images\PantheonImage.png

class discord {
    ; type = "Completed", "Loss", "Disconnect", "Reconnect", "Test", "Stopping"
    static SendEmbed(type) {
        global VersionText
        MacroRuntime := this.CalculateElapsedTime(MacroStartTime)
        StageRuntime := this.CalculateElapsedTime(StageStartTime)

        ; Set contents
        if type == "Completed" {
            title := ":tada: Stage Completed :tada:"
            fields := [{name : "Macro Runtime :stopwatch:", value : MacroRuntime, inline : true}, {name : "Stage Runtime :stopwatch:", value : StageRuntime, inline : true}]
            ping := SOPingE
            color := 0x62DD62
            hasImage := true
        }
        else if type == "Loss" {
            title := "Stage Loss"
            fields := [{name : "Macro Runtime :stopwatch:", value : MacroRuntime, inline : true}, {name : "Stage Runtime :stopwatch:", value : StageRuntime, inline : true}]
            ping := SOPingE
            color := 0xDD6262
            hasImage := true
        }
        else if type == "Disconnect" {
            title := ":exclamation: Client Disconnected :exclamation:"
            fields := [{name : "Disconnected At :stopwatch:", value : MacroRuntime, inline : true}, {name : "Stage Runtime :stopwatch:", value : StageRuntime, inline : true}]
            ping := DCPingE
            color := 0xDD6262
            hasImage := false
        }
        else if type == "Reconnect" {
            title := ":white_check_mark: Client Reconnected :white_check_mark:"
            fields := [{name : "Reconnected At :stopwatch:", value : MacroRuntime, inline : true}]
            ;ping := DCPingE
            color := 0x62DD62
            hasImage := true
        }
        else if type == "Test" {
            title := "Discord Connected"
            contents := "Webhook connected successfully"
            ping := PingE
            color := 0x62DD62
            hasImage := false
        } else if type == "Stopping" {
            title := ":octagonal_sign: Stopping Macro :octagonal_sign:"
            fields := [{name : "Stopped At :stopwatch:", value : MacroRuntime, inline : true}]
            color := 0x62DD62
            hasImage := false
        }

        ; Prepare embed and webhook
        Embed := EmbedBuilder()
        Embed.setAuthor({ name: "Pantheon Alert", icon_url: "https://i.imgur.com/a/MbHJG76.jpg" }) ; https://i.imgur.com/a/MbHJG76.jpg
        Embed.setTitle(title)
        try Embed.setDescription(contents)
        try embed.addFields(fields)
        Embed.setColor(color)
        if hasImage {
            this.CreateImage()
            Image := AttachmentBuilder(pBitmap)
            Embed.setImage(Image)
        }
        Embed.setFooter({ text: "Pantheon v" IsSet(VersionText) ? VersionText : "1.1.1" })

        try {
            if (WebhookURL != "") {
                global Webhook := WebHookBuilder(WebhookURL)
            }
        } catch {
            MsgBox("Your webhook URL is not valid.", "Webhook", 4096 + 0)
            return
        }

        ; Send embed
        try {
            if hasImage {
                Webhook.send({ embeds: [Embed], files: [image], content: (ping ? (pingE ? "<@" UserID ">" : "") : "") })
            }
            else {
                Webhook.send({ embeds: [Embed], content: (ping ? (pingE ? "<@" UserID ">" : "") : "") })
            }

            AddToLog("Sent webhook successfully")
        } catch {
            AddToLog("Failed to send webhook")
            AddToLog(title)
        }

        ; Clean up resources
        if hasImage {
            Gdip_DisposeImage(pBitmap)
            Gdip_Shutdown(pToken)
        }

    }

    static CreateImage() {
        global hwnd := GetRobloxHWND()
        global pToken := Gdip_Startup()
        if !pToken {
            MsgBox("Failed to initialize GDI+")
            return
        }

        global pBitmap := Gdip_BitmapFromScreen(deltaX + 8 "|" deltaY + 30 "|" 800 "|" 600)
        if !pBitmap {
            MsgBox("Failed to capture the screen")
            Gdip_Shutdown(pToken)
            return
        }
    }

    static CalculateElapsedTime(StartTime) {
        ElapsedTimeMs := A_TickCount - StartTime
        ElapsedTimeSec := Floor(ElapsedTimeMs / 1000)
        ElapsedHours := Floor(ElapsedTimeSec / 3600)
        ElapsedMinutes := Floor(Mod(ElapsedTimeSec, 3600) / 60)
        ElapsedSeconds := Mod(ElapsedTimeSec, 60)

        if ElapsedHours > 0 {
            Return Format("{}h {}m {}s", ElapsedHours, ElapsedMinutes, ElapsedSeconds)
        }
        else if ElapsedMinutes > 0 {
            Return Format("{}m {}s", ElapsedMinutes, ElapsedSeconds)
        }
        else {
            Return Format("{}s", ElapsedSeconds)
        }
    }
}