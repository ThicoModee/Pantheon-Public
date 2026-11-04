#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\Settings.ahk
#Include %A_LineFile%\..\framework\Packages.ahk

class MacroHub {
    static BundledRoot := A_ScriptDir "\macros"
    static ConfigPath := A_ScriptDir "\data\hub.json"
    static History := []
    static Config := Map("root", "", "accent", "violet", "theme", "default", "compact", 0, "scale", 100,
        "selected", "", "favorites", [], "developer", 0)

    static Mode(id) {
        if MacroPackages.Has(id)
            return id
        throw ValueError("Unknown macro.")
    }

    static Available(id) => MacroPackages.Has(id)

    static Initialize() {
        if FileExist(this.ConfigPath)
            this.Config := this.ValidateConfig(JSON.parse(FileRead(this.ConfigPath, "UTF-8")))
        this.Config["root"] := this.BundledRoot
        this.Log("Pantheon Hub is ready.")
    }

    static ValidateConfig(c) {
        if !(c is Map) || !(c["root"] is String) || StrLen(c["root"]) > 1024
            throw ValueError("Invalid hub preferences.")
        if !InStr("|violet|neutral|gold|", "|" c["accent"] "|")
            throw ValueError("Unknown accent colour.")
        if c["scale"] != 90 && c["scale"] != 100 && c["scale"] != 110
            throw ValueError("Unknown interface size.")
        theme := c.Get("theme", "default")
        FlowSchema.Enum(theme, ["default", "christmas", "midnight", "rose", "ember"], "interface theme")
        p := Map("theme", theme, "root", this.BundledRoot, "accent", c["accent"], "compact", ProfileStore.Int(c["compact"], 0, 1, "Sidebar"),
            "scale", c["scale"], "selected", this.Available(c["selected"]) ? this.Mode(c["selected"]) : "", "favorites", [],
            "developer", ProfileStore.Int(c.Get("developer", 0), 0, 1, "Developer mode"))
        if !(c["favorites"] is Array) || c["favorites"].Length > 64
            throw ValueError("Invalid favourites.")
        seen := Map()
        for id in c["favorites"] {
            if !this.Available(id)
                continue
            if !seen.Has(id)
                p["favorites"].Push(id), seen[id] := true
        }
        return p
    }

    static SavePreferences(raw) {
        raw["root"] := this.Config["root"]
        clean := this.ValidateConfig(raw)
        ProfileStore.WriteJson(this.ConfigPath, clean)
        this.Config := clean
        return clean
    }

    static LaunchPlan(id) {
        id := this.Mode(id)
        if MacroPackages.Has(id) {
            path := RegExReplace(A_LineFile, "[\\/][^\\/]+$") "\framework\Worker.ahk"
            SplitPath(path, , &directory)
            return Map("id", id, "path", path, "directory", directory, "command", '"' A_AhkPath '" "' path '"')
        }
        throw Error("Import or create a macro configuration first.")
    }

    static SelectWorkspace(id) {
        id := this.Mode(id)
        if HubEngine.State() == "running" || HubEngine.State() == "paused"
            if id != this.Config["selected"]
                throw Error("Stop the current macro before switching workspaces.")
        this.Config["selected"] := id
        GameMount.Enabled := true
        ProfileStore.WriteJson(this.ConfigPath, this.Config)
        return Map("selected", id)
    }

    static AnyOpen() => HubEngine.Busy()

    static Snapshot() {
        macros := MacroPackages.Catalog()
        return Map("config", this.Config, "macros", macros, "roblox", (GameMount.Hwnd || WinExist("ahk_exe RobloxPlayerBeta.exe")) ? 1 : 0,
            "mounted", GameMount.Hwnd && !GameMount.Hidden ? 1 : 0, "pinned", GameMount.Enabled ? 1 : 0, "engine", HubEngine.Snapshot(), "controls", HubControls.Read(), "history", this.History, "warnings", MacroPackages.Warnings)
    }

    static FocusRoblox() {
        if !(hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe"))
            throw Error("Open Roblox first, then try again.")
        WinActivate("ahk_id " hwnd)
        return Map("focused", 1)
    }

    static Log(message) {
        this.History.InsertAt(1, Map("time", FormatTime(, "HH:mm"), "message", message))
        if this.History.Length > 30
            this.History.Pop()
    }
}

class HubRegistry {
    static Write(key, values, name) {
        before := Map()
        for field in values {
            try {
                kind := "REG_SZ"
                loop reg key, "V"
                    if A_LoopRegName == field {
                        kind := A_LoopRegType
                        break
                    }
                before[field] := Map("exists", 1, "value", RegRead(key, field), "type", kind)
            } catch OSError {
                before[field] := Map("exists", 0, "value", "", "type", "REG_SZ")
            }
        }
        backup := A_ScriptDir "\data\backups\" name "-" FormatTime(, "yyyyMMdd-HHmmss") "-" A_TickCount ".json"
        ProfileStore.WriteJson(backup, Map("key", key, "values", before))
        written := []
        try {
            for field, value in values {
                RegWrite(String(value), "REG_SZ", key, field)
                written.Push(field)
            }
        } catch Error as err {
            rollbackFailed := false
            for field in written {
                old := before[field]
                try {
                    if old["exists"]
                        RegWrite(old["value"], old["type"], key, field)
                    else
                        RegDelete(key, field)
                } catch Error {
                    rollbackFailed := true
                }
            }
            throw Error("Settings could not be applied. " (rollbackFailed ? "Some settings could not be restored; backup: " backup : "Previous settings were restored.") " " err.Message)
        }
        return backup
    }
}

class HubControls {
    static Key := "HKEY_CURRENT_USER\Software\Pantheon"
    static Defaults := Map("resizeBind", "F1", "startBind", "F2", "pauseBind", "F4")
    static Read() {
        c := Map()
        for name, fallback in this.Defaults
            c[name] := RegRead(this.Key, name, fallback)
        return c
    }
    static Validate(raw) {
        clean := Map(), seen := Map()
        for name in this.Defaults {
            key := raw[name]
            if !(key is String) || !RegExMatch(key, "^(?:[!^+#]{0,4})(?:F(?:[1-9]|1[0-9]|2[0-4])|[A-Z0-9]|Space|Home|End|Insert|Delete|PgUp|PgDn|Up|Down|Left|Right)$")
                throw ValueError("Choose a supported keyboard shortcut for each control.")
            if seen.Has(key)
                throw ValueError("Each control needs a different shortcut.")
            seen[key] := true, clean[name] := key
        }
        return clean
    }
    static Apply(raw) {
        if MacroHub.AnyOpen()
            throw Error("Stop the macro before changing shortcuts.")
        clean := this.Validate(raw)
        HubRegistry.Write(this.Key, clean, "controls")
        MacroHub.Log("Updated macro keyboard shortcuts.")
        return clean
    }
}
