#Requires AutoHotkey v2.0

class FlowSettings {
    static Specs(definition) => definition.Get("settings", Map())
    static Spec(definition, id) {
        FlowSchema.Id(id)
        if !this.Specs(definition).Has(id)
            throw ValueError("Unknown macro setting: " id)
        return this.Specs(definition)[id]
    }
    static Option(spec, value) {
        for option in spec["options"]
            if option["value"] == value
                return option
        throw ValueError("Unknown setting option: " value)
    }
    static Value(spec, value) {
        switch spec["type"] {
            case "toggle", "checkbox": FlowSchema.Int(value, 0, 1, "Toggle value")
            case "number": FlowSchema.Int(value, spec["min"], spec["max"], "Setting value")
            case "select": this.Option(spec, value)
            case "key": return PlayControls.Key(value)
            case "multiselect", "priority":
                if !(value is Array) || value.Length > spec["options"].Length
                    throw ValueError("Invalid setting selections.")
                seen := Map()
                for item in value {
                    this.Option(spec, item)
                    if seen.Has(item)
                        throw ValueError("Duplicate setting selection.")
                    seen[item] := true
                }
            default: throw ValueError("Unsupported macro setting type.")
        }
        return value
    }
    static Validate(definition) {
        specs := this.Specs(definition)
        if !(specs is Map) || specs.Count > 32
            throw ValueError("A macro supports up to 32 settings.")
        for id, spec in specs {
            FlowSchema.Id(id), FlowSchema.Keys(spec, "label|type|default|min|max|options|control")
            FlowSchema.Text(spec["label"], 80, "setting label")
            FlowSchema.Enum(spec["type"], ["toggle", "checkbox", "number", "select", "multiselect", "priority", "key"], "setting control")
            if spec["type"] == "key" && !spec.Has("control")
                throw ValueError("Choose an in-game action for this key override.")
            if spec.Has("control") {
                if spec["type"] != "key"
                    throw ValueError("Only key settings can override an in-game control.")
                PlayControls.Control(spec["control"])
            }
            if Trim(spec["label"]) == ""
                throw ValueError("Macro settings need a visible label.")
            if spec["type"] == "number" {
                FlowSchema.Int(spec["min"], 0, 1000000, "Setting minimum")
                FlowSchema.Int(spec["max"], spec["min"], 1000000, "Setting maximum")
            } else if spec.Has("min") || spec.Has("max")
                throw ValueError("Only number settings have numeric bounds.")
            if spec["type"] == "select" || spec["type"] == "multiselect" || spec["type"] == "priority" {
                if !(spec["options"] is Array) || spec["options"].Length < 1 || spec["options"].Length > 32
                    throw ValueError("Choice settings need one to 32 options.")
                seen := Map()
                for option in spec["options"] {
                    FlowSchema.Keys(option, "value|label|target|map"), FlowSchema.Id(option["value"])
                    FlowSchema.Text(option["label"], 80, "option label")
                    if Trim(option["label"]) == ""
                        throw ValueError("Setting options need a visible label.")
                    if seen.Has(option["value"])
                        throw ValueError("Duplicate setting option.")
                    seen[option["value"]] := true
                    if option.Get("map", "") != "" && !definition.Get("maps", Map()).Has(option["map"])
                        throw ValueError("Setting option refers to an unknown placement map.")
                    if option.Get("target", "") != ""
                        FlowSchema.Target(definition, option["target"])
                }
            } else if spec.Has("options")
                throw ValueError("This setting does not support options.")
            this.Value(spec, spec["default"])
        }
    }
    static Values(definition, raw) {
        if !(raw is Map)
            throw ValueError("Invalid macro settings.")
        specs := this.Specs(definition), result := Map()
        for id in raw
            if !specs.Has(id)
                throw ValueError("Unknown saved setting: " id)
        for id, spec in specs
            result[id] := this.Value(spec, raw.Get(id, spec["default"]))
        return result
    }
    static Check(definition, check) {
        FlowSchema.Keys(check, "setting|comparison|value")
        spec := this.Spec(definition, check["setting"]), op := check["comparison"]
        if spec["type"] == "key"
            check["value"] := PlayControls.Key(check["value"])
        FlowSchema.Enum(op, ["equals", "not-equals", "greater", "less", "contains", "not-contains"], "setting comparison")
        if spec["type"] == "priority" || spec["type"] == "multiselect" {
            if op != "contains" && op != "not-contains"
                throw ValueError("List settings support contains / does not contain.")
            this.Option(spec, check["value"])
        } else {
            if op != "equals" && op != "not-equals" && !(spec["type"] == "number" && (op == "greater" || op == "less"))
                throw ValueError("Unsupported setting comparison.")
            this.Value(spec, check["value"])
        }
    }
    static Match(values, check) {
        value := values[check["setting"]], expected := check["value"]
        switch check["comparison"] {
            case "equals": return value == expected
            case "not-equals": return value != expected
            case "greater": return value > expected
            case "less": return value < expected
            case "contains", "not-contains":
                found := false
                for item in value
                    if item == expected
                        found := true
                return check["comparison"] == "contains" ? found : !found
        }
    }
    static Parameter(definition, value, low, high, label) {
        if value is Map {
            FlowSchema.Keys(value, "setting")
            spec := this.Spec(definition, value["setting"])
            if spec["type"] == "number"
                min := spec["min"], max := spec["max"]
            else if low == 0 && high == 1 && (spec["type"] == "toggle" || spec["type"] == "checkbox")
                min := 0, max := 1
            else
                throw ValueError(label " needs a numeric setting.")
            if min < low || max > high
                throw ValueError(label " requires a setting bounded from " low " to " high ".")
        } else
            FlowSchema.Int(value, low, high, label)
    }
}
