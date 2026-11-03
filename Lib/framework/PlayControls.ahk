#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\..\Settings.ahk

class PlayControls {
    static Defaults() => Map("slot-1", "1", "slot-2", "2", "slot-3", "3", "slot-4", "4", "slot-5", "5", "slot-6", "6", "upgrade", "R", "sell", "X", "cancel", "Q", "targeting", "T", "auto-upgrade", "K")
    static Key(value) {
        if !(value is String)
            throw ValueError("Invalid in-game key.")
        value := RegExReplace(value, "^key-", "")
        if RegExMatch(value, "i)^[a-z0-9]$")
            return StrUpper(value)
        if RegExMatch(value, "i)^F([1-9]|1[0-9]|2[0-4])$")
            return StrUpper(value)
        for key in ["Backspace", "Delete", "Insert", "Home", "End", "PgUp", "PgDn", "Space", "Tab", "Enter", "Escape", "Up", "Down", "Left", "Right", "Shift", "Control"]
            if StrLower(value) == StrLower(key)
                return key
        throw ValueError("Unsupported in-game key: " value)
    }
    static Control(id) {
        if !this.Defaults().Has(id)
            throw ValueError("Choose a supported in-game action.")
        return id
    }
    static Validate(raw) {
        FlowSchema.Keys(raw, "slot-1|slot-2|slot-3|slot-4|slot-5|slot-6|upgrade|sell|cancel|targeting|auto-upgrade")
        clean := Map()
        for id, fallback in this.Defaults()
            clean[id] := this.Key(raw.Get(id, fallback))
        return clean
    }
    static Load() {
        path := A_ScriptDir "\data\ingame-controls.json"
        return FileExist(path) ? this.Validate(JSON.parse(FileRead(path, "UTF-8"))) : this.Defaults()
    }
    static Save(raw) {
        clean := this.Validate(raw)
        ProfileStore.WriteJson(A_ScriptDir "\data\ingame-controls.json", clean)
        return clean
    }
    static Upgrade(definition) {
        controls := definition.Get("controls", Map())
        for action, binding in controls.Clone() {
            if !(binding is Map) || !binding.Has("setting")
                continue
            specs := FlowSettings.Specs(definition), id := binding["setting"]
            if !specs.Has(id) || specs[id]["type"] != "select"
                continue
            spec := specs[id]
            this.Control(action)
            for option in spec["options"]
                this.Key(option["value"])
            specs[id] := Map("label", spec["label"], "type", "key", "default", this.Key(spec["default"]), "control", action)
            controls.Delete(action)
        }
        return definition
    }
    static Definition(definition) {
        seen := Map()
        for id, spec in FlowSettings.Specs(definition)
            if spec["type"] == "key" && spec.Has("control") {
                if seen.Has(spec["control"])
                    throw ValueError("Each in-game action can have only one key override setting.")
                seen[spec["control"]] := true
            }
        controls := definition.Get("controls", Map())
        FlowSchema.Keys(controls, "slot-1|slot-2|slot-3|slot-4|slot-5|slot-6|upgrade|sell|cancel|targeting|auto-upgrade")
        for id, binding in controls {
            if binding is Map {
                FlowSchema.Keys(binding, "setting")
                spec := FlowSettings.Spec(definition, binding["setting"])
                if spec["type"] == "key"
                    this.Key(spec["default"])
                else if spec["type"] != "select"
                    throw ValueError("Key overrides require a dropdown setting.")
                if spec["type"] == "select"
                    for option in spec["options"]
                        this.Key(option["value"])
            } else
                this.Key(binding)
        }
    }
    static Resolve(definition, values, defaults) {
        clean := this.Validate(defaults)
        for id, binding in definition.Get("controls", Map())
            clean[id] := this.Key(binding is Map ? values[binding["setting"]] : binding)
        seen := Map()
        for setting, spec in FlowSettings.Specs(definition) {
            if spec["type"] != "key" || !spec.Has("control")
                continue
            control := this.Control(spec["control"])
            if seen.Has(control)
                throw ValueError("More than one key setting overrides " control ".")
            seen[control] := true
            clean[control] := this.Key(values[setting])
        }
        return clean
    }
}
