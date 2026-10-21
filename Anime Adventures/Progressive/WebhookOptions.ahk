#Requires AutoHotkey v2.0

#Include Progressive.ahk

#Include ..\..\
#Include Lib\Discord-Webhook-master\lib\WEBHOOK.ahk
#Include Lib\Gdip_All.ahk

class discord {
    ; type = "Completed", "Loss", "Disconnect", "Reconnect", "Test", "Stopping", "Shop"
    static SendEmbed(type) {
        try {
            MacroRuntime := this.CalculateElapsedTime(MacroStartTime)
            StageRuntime := this.CalculateElapsedTime(StageStartTime)
        }

        WebhookTypes := Map(
            "Completed", {
                title: ":tada: Stage Completed :tada:",
                fields: [{ name: "Macro Runtime :stopwatch:", value: MacroRuntime, inline: true }, { name: "Stage Runtime :stopwatch:",
                    value: StageRuntime, inline: true }],
                ping: SOPingE,
                color: 0x62DD62,
                hasImage: true
            },
            "Loss", {
                title: "Stage Loss",
                fields: [{ name: "Macro Runtime :stopwatch:", value: MacroRuntime, inline: true }, { name: "Stage Runtime :stopwatch:",
                    value: StageRuntime, inline: true }],
                ping: SOPingE,
                color: 0xDD6262,
                hasImage: true
            },
            "Disconnect", {
                title: ":exclamation: Client Disconnected :exclamation:",
                fields: [{ name: "Disconnected At :stopwatch:", value: MacroRuntime, inline: true }, { name: "Stage Runtime :stopwatch:",
                    value: StageRuntime, inline: true }],
                ping: DCPingE,
                color: 0xDD6262,
                hasImage: false
            },
            "Reconnect", {
                title: ":white_check_mark: Client Reconnected :white_check_mark:",
                fields: [{ name: "Reconnected At :stopwatch:", value: MacroRuntime, inline: true }],
                ping: false,
                color: 0x62DD62,
                hasImage: true
            },
            "Test", {
                title: "Discord Connected",
                contents: "Webhook connected successfully",
                ping: PingE,
                color: 0x62DD62,
                hasImage: false
            },
            "Stopping", {
                title: ":octagonal_sign: Couldn't enter dungeon! :octagonal_sign:",
                fields: [{ name: "Error", value: "You ran out of keys! Getting more!" }],
                ping: false,
                color: 0xDD6262,
                hasImage: false
            },
            "Shop", {
                title: "Success!",
                contents: "Shop Captured",
                ping: false,
                color: 0x62DD62,
                hasImage: true
            }
        )

        ; Prepare embed and webhook
        Embed := EmbedBuilder()
        Embed.setAuthor({ name: "Pantheon Alert", icon_url: "https://i.imgur.com/a/MbHJG76.jpg" }) ; https://i.imgur.com/a/MbHJG76.jpg
        Embed.setTitle(WebhookTypes.Get(type).title)
        try Embed.setDescription(WebhookTypes.Get(type).contents)
        try embed.addFields(WebhookTypes.Get(type).fields)
        Embed.setColor(WebhookTypes.Get(type).color)
        if WebhookTypes.Get(type).hasImage {
            this.CreateImage()
            Image := AttachmentBuilder(pBitmap)
            Embed.setImage(Image)
        }
        Embed.setFooter({ text: "Pantheon v" VersionText })

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
            if WebhookTypes.Get(type).hasImage {
                Webhook.send({ embeds: [Embed], files: [image], content: (WebhookTypes.Get(type).ping ? (pingE ? "<@" UserID ">" :
                    "") : "") })
            }
            else {
                Webhook.send({ embeds: [Embed], content: (WebhookTypes.Get(type).ping ? (pingE ? "<@" UserID ">" : "") :
                    "") })
            }

            AddToLog("Sent webhook successfully")
        } catch {
            AddToLog("Failed to send webhook")
        }

        ; Clean up resources
        if WebhookTypes.Get(type).hasImage {
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
            return Format("{}h {}m {}s", ElapsedHours, ElapsedMinutes, ElapsedSeconds)
        }
        else if ElapsedMinutes > 0 {
            return Format("{}m {}s", ElapsedMinutes, ElapsedSeconds)
        }
        else {
            return Format("{}s", ElapsedSeconds)
        }
    }
}
