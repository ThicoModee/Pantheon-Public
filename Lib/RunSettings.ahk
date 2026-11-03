#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\HubModel.ahk

class RunSettings {
    static RegistryRoot := "HKEY_CURRENT_USER\Software\Pantheon"
    static SchemaPath := A_ScriptDir "\Lib\ui\run-settings-schema.json"
    static Schema() => JSON.parse(FileRead(this.SchemaPath, "UTF-8"))
    static Fields(mode) {
        if mode != "general"
            throw ValueError("Macro settings are defined by their configuration.")
        return this.Schema()["general"]
    }
    static Key(mode) => this.RegistryRoot
    static Check(field, value) {
        kind := field["type"]
        if kind == "toggle" || kind == "select" {
            if value is String && RegExMatch(value, "^\d+$")
                value := Integer(value)
            if kind == "select"
                return ProfileStore.Int(value, 1, field["options"].Length, field["label"])
            on := field.Get("on", 1), off := field.Get("off", 0)
            if !(value is Integer) || (value != on && value != off)
                throw ValueError("Invalid value for " field["label"] ".")
            return value
        }
        if !(value is String) || StrLen(value) > field.Get("maxLength", 2048) || RegExMatch(value, '[\x00-\x1f]')
            throw ValueError("Invalid " field["label"] ".")
        format := field.Get("format", "")
        if (format == "server" || format == "webhook") && InStr(value, '"')
            throw ValueError("Invalid " field["label"] ".")
        if value != "" {
            if format == "server" && !RegExMatch(value, "i)^https://(?:www\.)?roblox\.com/(?:games/\d+/[^\s]*[?&]privateServerLinkCode=[a-z0-9]{32}(?:&[^\s]*)?|share\?code=[a-z0-9]+&type=Server)$")
                throw ValueError("Enter a Roblox private-server link.")
            if format == "webhook" && !RegExMatch(value, "i)^https://(?:(?:canary|ptb)\.)?discord(?:app)?\.com/api/(?:v\d+/)?webhooks/\d+/[a-z0-9_-]+$")
                throw ValueError("Enter a Discord webhook URL.")
            if format == "userId" && !RegExMatch(value, "^\d{15,22}$")
                throw ValueError("Enter a Discord user ID.")
            if format == "waves" && (!RegExMatch(value, "^\d{1,6}$") || Integer(value) < 1)
                throw ValueError("Leave wave must be a positive number, or blank.")
        }
        return value
    }
    static Validate(mode, raw) {
        if !(raw is Map)
            throw ValueError("Invalid macro settings.")
        clean := Map()
        for field in this.Fields(mode) {
            key := field["key"]
            if !raw.Has(key)
                throw ValueError("Missing " field["label"] ".")
            clean[key] := this.Check(field, raw[key])
        }
        if mode == "general" {
            if clean["WebhookE"] && clean["WebhookURL"] == ""
                throw ValueError("Enter a webhook URL before enabling webhooks.")
            if clean["PingE"] && clean["UserID"] == ""
                throw ValueError("Enter a Discord user ID before enabling pings.")
        }
        return clean
    }
    static Load(mode) {
        values := Map(), warnings := []
        for field in this.Fields(mode) {
            try values[field["key"]] := this.Check(field, RegRead(this.Key(mode), field["key"], field["default"]))
            catch Error {
                values[field["key"]] := field["default"]
                warnings.Push(field["label"] " has an invalid saved value. Review and save these settings.")
            }
        }
        return Map("values", values, "warnings", warnings)
    }
    static Save(mode, values) {
        if HubEngine.State() == "running" || HubEngine.State() == "paused" || (HubEngine.State() == "initializing" || HubEngine.State() == "reconnecting")
            throw Error("Stop the macro before changing its settings.")
        values := this.Validate(mode, values)
        HubRegistry.Write(this.Key(mode), values, "run-" mode)
        return Map("values", values)
    }
    static TestWebhook() {
        values := this.Load("general")["values"]
        if values["WebhookURL"] == ""
            throw Error("Save a webhook URL first.")
        request := ComObject("WinHttp.WinHttpRequest.5.1")
        request.SetTimeouts(5000, 5000, 5000, 10000)
        request.Open("POST", values["WebhookURL"], false)
        request.Option[6] := false
        request.SetRequestHeader("Content-Type", "application/json")
        ping := values["PingE"] && values["UserID"] != ""
        mentions := Map("parse", [], "users", ping ? [values["UserID"]] : [])
        request.Send(JSON.stringify(Map("content", "Pantheon webhook test" (ping ? " <@" values["UserID"] ">" : ""), "allowed_mentions", mentions)))
        if request.Status < 200 || request.Status >= 300
            throw Error("Webhook test failed (HTTP " request.Status ").")
        return Map("message", "Webhook test sent.")
    }
}
