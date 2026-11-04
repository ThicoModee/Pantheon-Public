#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\Settings.ahk
#Include %A_LineFile%\..\PlayControls.ahk
#Include %A_LineFile%\..\PlacementPlan.ahk
#Include %A_LineFile%\..\FlowErrors.ahk
#Include %A_LineFile%\..\ManagedUpgrade.ahk
#Include %A_LineFile%\..\PlacementFeedback.ahk
class FlowSchema {
    static Actions := ["click-point", "click", "click-setting", "move", "walk", "scroll", "wait", "delay", "press", "key", "call", "repeat", "for-setting", "if", "retry", "until", "stop", "camera", "placements", "outcome", "click-wait", "scroll-option", "dismiss", "setting-call"]
    static Keys(raw, allowed) {
        if !(raw is Map)
            throw ValueError("Expected a definition object.")
        for key in raw {
            if key == "name" && raw.Has("action") && raw.Has("id") {
                this.Text(raw["name"], 80, "step name")
                continue
            }
            valid := false
            for field in StrSplit(allowed, "|")
                if key == field
                    valid := true
            if !valid
                throw ValueError("Unknown definition field: " key)
        }
    }
    static Int(value, low, high, label) {
        if !(value is Integer) || value < low || value > high
            throw ValueError(label " must be an integer from " low " to " high ".")
        return value
    }
    static Text(value, maxLength, label) {
        if !(value is String) || StrLen(value) > maxLength || RegExMatch(value, "[\x00-\x1f]")
            throw ValueError("Invalid " label ".")
        return value
    }
    static Id(value) {
        if !(value is String) || !RegExMatch(value, "^[a-z][a-z0-9-]{0,47}$")
            throw ValueError("Use lowercase letters, digits and hyphens for identifiers.")
        return value
    }
    static Enum(value, choices, label) {
        if value is String
            for choice in choices
                if value == choice
                    return value
        throw ValueError("Unsupported " label ".")
    }
    static Pattern(text) {
        this.Text(text, 100000, "FindText capture")
        if text == "" || StrLen(text) > 100000
            throw ValueError("A FindText capture is required.")
        count := 0
        for part in StrSplit(text, "|") {
            if part == "" && count == 0
                continue
            count++
            if count > 8 || !RegExMatch(part, "^<[^<>]{0,64}>\*(\d{1,3})\$(\d{1,3})\.([0-9+/A-Za-z]+)$", &m)
                throw ValueError("Use grayscale FindText captures in framework targets.")
            if Integer(m[1]) > 255 || Integer(m[2]) < 1 || Integer(m[2]) > 800
                throw ValueError("Invalid FindText threshold or width.")
            alphabet := "0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", bits := ""
            loop parse, m[3] {
                n := InStr(alphabet, A_LoopField, true)-1
                loop 6
                    bits .= (n >> (6-A_Index)) & 1
            }
            if !RegExMatch(bits, "10*$")
                throw ValueError("Invalid FindText padding.")
            bits := RegExReplace(bits, "10*$")
            if !StrLen(bits) || Mod(StrLen(bits), Integer(m[2])) || StrLen(bits)//Integer(m[2]) > 600
                throw ValueError("Invalid FindText capture height.")
        }
        return text
    }
    static Validate(raw) {
        this.Keys(raw, "version|game|mode|name|client|targets|workflows|settings|entry|runMode|icon|maps|controls|playback")
        if raw.Has("icon")
            this.Enum(raw["icon"], ["pantheon", "dungeons", "progressive", "raids", "challenges", "winter"], "macro icon")
        if raw.Has("runMode")
            this.Enum(raw["runMode"], ["once", "repeat"], "run mode")
        this.Int(raw["version"], 1, 1, "Definition version")
        this.Id(raw["game"]), this.Id(raw["mode"]), this.Text(raw["name"], 100, "definition name")
        this.Keys(raw["client"], "width|height")
        this.Int(raw["client"]["width"], 800, 800, "Client width"), this.Int(raw["client"]["height"], 600, 600, "Client height")
        if !(raw["targets"] is Map) || raw["targets"].Count > 128 || !(raw["workflows"] is Map) || raw["workflows"].Count < 1 || raw["workflows"].Count > 32
            throw ValueError("Definition has too many targets or workflows.")
        for id, t in raw["targets"] {
            this.Id(id), this.Keys(t, "name|kind|pattern|x|y|width|height|error1|error0|offsetX|offsetY")
            this.Text(t["name"], 80, "target name")
            this.Enum(t["kind"], ["point", "pattern"], "target type")
            if t["kind"] != "point" && t["kind"] != "pattern"
                throw ValueError("Unknown target kind.")
            this.Text(t["pattern"], 100000, "FindText capture")
            if t["kind"] == "pattern"
                if t["pattern"] == ""
                    throw ValueError("Capture an image for target: " t["name"])
                else
                    this.Pattern(t["pattern"])
            else if t["pattern"] != ""
                throw ValueError("Coordinate targets cannot contain a capture.")
            this.Int(t["x"], 0, 799, "Target X"), this.Int(t["y"], 0, 599, "Target Y")
            this.Int(t["width"], 1, 800-t["x"], "Target width"), this.Int(t["height"], 1, 600-t["y"], "Target height")
            this.Int(t["error1"], 0, 20, "Foreground mismatch"), this.Int(t["error0"], 0, 20, "Background mismatch")
            this.Int(t["offsetX"], -799, 799, "Click offset X"), this.Int(t["offsetY"], -599, 599, "Click offset Y")
        }
        maps := raw.Get("maps", Map())
        if !(maps is Map) || maps.Count > 48
            throw ValueError("A macro supports up to 48 maps.")
        for id, mapSpec in maps {
            this.Id(id), this.Keys(mapSpec, "name|parent"), this.Text(mapSpec["name"], 80, "map name")
            if id == "shared" || id == "selected" || Trim(mapSpec["name"]) == ""
                throw ValueError("Choose a unique map name and identifier.")
        }
        for id, mapSpec in maps {
            parent := mapSpec.Get("parent", "")
            if parent != "" {
                this.Id(parent)
                if parent == id || !maps.Has(parent) || maps[parent].Get("parent", "") != ""
                    throw ValueError("Map children must belong to a top-level map.")
            }
        }
        playback := PlacementPlan.Config(raw.Get("playback", Map()))
        if playback.Has("managedUpgrade")
            ManagedUpgrade.Config(playback["managedUpgrade"], raw)
        if playback.Has("placementFeedback")
            PlacementFeedback.Config(playback["placementFeedback"], raw)
        FlowSettings.Validate(raw)
        PlayControls.Definition(raw)
        if raw.Has("entry")
            this.Reference(raw, raw["entry"])
        total := 0
        for id, flow in raw["workflows"] {
            this.Id(id), this.Keys(flow, "name|steps"), this.Text(flow["name"], 80, "workflow name")
            this.Steps(raw, flow["steps"], &total, 0)
        }
        done := Map()
        for id in raw["workflows"]
            this.Visit(raw, id, Map(), 0, done)
        return raw
    }
    static Point(raw, definition := unset) {
        if IsSet(definition)
            this.Param(definition, raw["x"], 0, 799, "X"), this.Param(definition, raw["y"], 0, 599, "Y")
        else
            this.Int(raw["x"], 0, 799, "X"), this.Int(raw["y"], 0, 599, "Y")
    }
    static Param(raw, value, low, high, label) => FlowSettings.Parameter(raw, value, low, high, label)
    static Maximum(raw, value) => value is Map ? FlowSettings.Spec(raw, value["setting"]).Get("max", 1) : value
    static Failure(value) {
        this.Enum(value, ["error", "continue"], "failure behaviour")
    }
    static Condition(raw, condition, depth := 0, &nodes := unset) {
        if !IsSet(nodes)
            nodes := 0
        if ++nodes > 64
            throw ValueError("An image condition supports up to 64 checks and groups.")
        if depth > 3
            throw ValueError("Image conditions can have up to four group levels.")
        this.Keys(condition, "operator|checks")
        this.Enum(condition["operator"], ["all", "any"], "condition operator")
        if condition["operator"] != "all" && condition["operator"] != "any"
            throw ValueError("Choose AND or OR for the image group.")
        if !(condition["checks"] is Array) || condition["checks"].Length < 1 || condition["checks"].Length > 8
            throw ValueError("An image group needs between one and eight checks.")
        for check in condition["checks"] {
            if check.Has("operator")
                this.Condition(raw, check, depth+1, &nodes)
            else if check.Has("selectedImage") {
                this.Keys(check, "selectedImage|state")
                this.Enum(check["state"], ["present", "absent"], "image check")
                spec := FlowSettings.Spec(raw, check["selectedImage"])
                if spec["type"] != "select"
                    throw ValueError("Selected image checks require a dropdown setting.")
                for option in spec["options"] {
                    this.Target(raw, option.Get("target", ""))
                    if raw["targets"][option["target"]]["kind"] != "pattern"
                        throw ValueError("Every dropdown option must map to a FindText image.")
                }
            } else if check.Has("setting")
                FlowSettings.Check(raw, check)
            else {
                this.Keys(check, "target|state"), this.Target(raw, check["target"])
                this.Enum(check["state"], ["present", "absent"], "image check")
                if raw["targets"][check["target"]]["kind"] != "pattern"
                    throw ValueError("Image checks require a FindText capture.")
                if check["state"] != "present" && check["state"] != "absent"
                    throw ValueError("Choose image detected or not detected.")
            }
        }
    }
    static Steps(raw, steps, &total, depth) {
        if depth > 8 || !(steps is Array) || steps.Length > 100
            throw ValueError("Step groups support up to 100 steps and eight nested levels.")
        ids := Map()
        for step in steps {
                if ++total > 1000
                    throw ValueError("A definition supports up to 1000 steps.")
                this.Id(step["id"])
                this.Enum(step["action"], this.Actions, "sequence action")
                if step.Has("button")
                    this.Enum(step["button"], ["Left", "Right"], "mouse button")
                if step.Has("missing")
                    this.Enum(step["missing"], ["error", "skip"], "missing-image behaviour")
                if ids.Has(step["id"])
                    throw ValueError("Duplicate step identifier.")
                ids[step["id"]] := true
                switch step["action"] {
                    case "camera":
                        this.Keys(step, "id|action|zoomIn|zoomOut|tilt")
                        this.Int(step["zoomIn"], 1, 50, "Zoom in ticks"), this.Int(step["zoomOut"], 1, 50, "Zoom out ticks")
                        this.Int(step["tilt"], 30, 299, "Camera tilt")
                    case "placements":
                        this.Keys(step, "id|action|route|fallback|setting")
                        this.Enum(step["fallback"], ["shared", "error"], "placement fallback")
                        if step["route"] == "setting" {
                            spec := FlowSettings.Spec(raw, step["setting"])
                            if spec["type"] != "select"
                                throw ValueError("Map selection requires a dropdown.")
                            for option in spec["options"]
                                if !raw.Get("maps", Map()).Has(option.Get("map", ""))
                                    throw ValueError("Map every dropdown option to a placement map.")
                        }
                        if step["route"] != "setting" && step["route"] != "selected" && step["route"] != "shared" && !raw.Get("maps", Map()).Has(step["route"])
                            throw ValueError("Choose a map defined by this macro or the player's selected setup.")
                    case "click-wait", "dismiss":
                        this.Keys(step, step["action"] == "click-wait" ? "id|action|target|ready|button|attempts|timeoutMs|intervalMs" : "id|action|target|ready|button|timeoutMs|intervalMs")
                        this.Target(raw, step["target"]), this.Target(raw, step["ready"])
                        if raw["targets"][step["ready"]]["kind"] != "pattern" || step["target"] == step["ready"]
                            throw ValueError("Choose a separate ready image that confirms the next screen.")
                        this.Enum(step["button"], ["Left", "Right"], "mouse button")
                        this.Param(raw, step["timeoutMs"], 100, 60000, "Component timeout")
                        this.Param(raw, step["intervalMs"], 100, 5000, "Component interval")
                        if step["action"] == "click-wait"
                            this.Param(raw, step["attempts"], 1, 5, "Click attempts")
                    case "scroll-option":
                        this.Keys(step, "id|action|setting|x|y|direction|maxScrolls|timeoutMs|intervalMs")
                        spec := FlowSettings.Spec(raw, step["setting"])
                        if spec["type"] != "select"
                            throw ValueError("Scroll to option requires a dropdown setting.")
                        for option in spec["options"] {
                            this.Target(raw, option.Get("target", ""))
                            if raw["targets"][option["target"]]["kind"] != "pattern"
                                throw ValueError("Map each dropdown option to a captured image before scrolling to it.")
                        }
                        this.Point(step, raw), this.Enum(step["direction"], ["Up", "Down"], "scroll direction")
                        this.Param(raw, step["maxScrolls"], 1, 100, "Maximum scrolls")
                        this.Param(raw, step["timeoutMs"], 100, 60000, "Scroll timeout")
                        this.Param(raw, step["intervalMs"], 100, 5000, "Scroll interval")
                    case "setting-call":
                        this.Keys(step, "id|action|setting|routes")
                        spec := FlowSettings.Spec(raw, step["setting"])
                        if spec["type"] != "select" || !(step["routes"] is Map) || step["routes"].Count != spec["options"].Length
                            throw ValueError("Map every dropdown option to a sequence.")
                        for option in spec["options"] {
                            if !step["routes"].Has(option["value"])
                                throw ValueError("Choose a sequence for option: " option["label"])
                            this.Reference(raw, step["routes"][option["value"]])
                        }
                    case "outcome":
                        this.Keys(step, "id|action|victory|defeat|timeoutMs|thenSteps|elseSteps")
                        for field in ["victory", "defeat"] {
                            this.Target(raw, step[field])
                            if raw["targets"][step[field]]["kind"] != "pattern"
                                throw ValueError("Match results require captured images.")
                        }
                        if step["victory"] == step["defeat"]
                            throw ValueError("Choose different Victory and Defeat images.")
                        this.Param(raw, step["timeoutMs"], 100, 3600000, "Match result timeout")
                        this.Steps(raw, step["thenSteps"], &total, depth+1), this.Steps(raw, step["elseSteps"], &total, depth+1)
                    case "stop": this.Keys(step, "id|action")
                    case "click-point":
                        this.Keys(step, "id|action|x|y|button"), this.Point(step, raw)
                        if step["button"] != "Left" && step["button"] != "Right"
                            throw ValueError("Choose left or right click.")
                    case "move":
                        this.Keys(step, "id|action|x|y"), this.Point(step, raw)
                    case "walk":
                        this.Keys(step, "id|action|keys|sprint|sprintKey|durationMs")
                        if !(step["keys"] is Array) || step["keys"].Length < 1 || step["keys"].Length > 2
                            throw ValueError("Choose one or two movement directions.")
                        directions := Map()
                        for key in step["keys"] {
                            if !RegExMatch(key, "^[WASD]$") || directions.Has(key)
                                throw ValueError("Walking only supports distinct W, A, S and D keys.")
                            directions[key] := true
                        }
                        if (directions.Has("W") && directions.Has("S")) || (directions.Has("A") && directions.Has("D"))
                            throw ValueError("Choose movement directions that do not oppose each other.")
                        this.Param(raw, step["sprint"], 0, 1, "Sprint")
                        if step["sprintKey"] != "Shift" && step["sprintKey"] != "Control"
                            throw ValueError("Choose Shift or Control for sprint.")
                        this.Enum(step["sprintKey"], ["Shift", "Control"], "sprint key")
                        this.Param(raw, step["durationMs"], 30, 30000, "Walking duration")
                    case "scroll":
                        this.Enum(step["direction"], ["Up", "Down"], "scroll direction")
                        this.Keys(step, "id|action|direction|ticks|count|intervalMs")
                        if step["direction"] != "Up" && step["direction"] != "Down"
                            throw ValueError("Choose scroll up or down.")
                        this.Param(raw, step["ticks"], 1, 10, "Scroll amount"), this.Param(raw, step["count"], 1, 100, "Scroll repeats")
                        this.Param(raw, step["intervalMs"], 0, 5000, "Scroll interval")
                        if this.Maximum(raw, step["count"])*this.Maximum(raw, step["intervalMs"]) > 60000
                            throw ValueError("A scroll step cannot take longer than one minute.")
                    case "click-setting":
                        this.Keys(step, "id|action|setting|timeoutMs|missing|button")
                        spec := FlowSettings.Spec(raw, step["setting"])
                        if spec["type"] != "select" && spec["type"] != "multiselect" && spec["type"] != "priority"
                            throw ValueError("Choose a dropdown or list setting for this step.")
                        for option in spec["options"]
                            if option.Get("target", "") == ""
                                throw ValueError("Map each option to an image or coordinate for setting: " spec["label"])
                        this.Param(raw, step["timeoutMs"], 0, 60000, "Timeout")
                        if step["missing"] != "skip" && step["missing"] != "error"
                            throw ValueError("Unknown missing-target behaviour.")
                        if step["button"] != "Left" && step["button"] != "Right"
                            throw ValueError("Choose left or right click.")
                    case "click", "wait":
                        this.Keys(step, step.Has("condition") ? "id|action|condition|timeoutMs|missing" : "id|action|target|timeoutMs|missing|button")
                        if step["action"] == "wait" && step.Has("condition")
                            this.Condition(raw, step["condition"])
                        else
                            this.Target(raw, step["target"])
                        if step.Has("button") && step["button"] != "Left" && step["button"] != "Right"
                            throw ValueError("Choose left or right click.")
                        this.Param(raw, step["timeoutMs"], step["action"] == "wait" ? 100 : 0, step["action"] == "wait" ? 3600000 : 60000, "Timeout")
                        if step["missing"] != "skip" && step["missing"] != "error"
                            throw ValueError("Unknown missing-target behaviour.")
                    case "delay":
                        this.Keys(step, "id|action|durationMs"), this.Param(raw, step["durationMs"], 0, 60000, "Delay")
                    case "key", "press":
                        this.Keys(step, step["action"] == "key" ? "id|action|key|durationMs" : "id|action|key|count|intervalMs")
                        if !RegExMatch(step["key"], "^(?:[A-Z0-9]|Space|Tab|Enter|Escape|Up|Down|Left|Right|Shift|Control)$")
                            throw ValueError("Unsupported key.")
                        if step["action"] == "key"
                            this.Param(raw, step["durationMs"], 30, 10000, "Key duration")
                        else {
                            this.Param(raw, step["count"], 1, 20, "Key presses")
                            this.Param(raw, step["intervalMs"], 0, 5000, "Key interval")
                        }
                    case "for-setting":
                        this.Keys(step, "id|action|setting|steps")
                        spec := FlowSettings.Spec(raw, step["setting"])
                        if spec["type"] != "multiselect" && spec["type"] != "priority"
                            throw ValueError("Choose a checkbox list or priority setting to iterate.")
                        this.Steps(raw, step["steps"], &total, depth+1)
                    case "call", "repeat":
                        this.Keys(step, step["action"] == "call" ? "id|action|workflow" : step.Has("steps") ? "id|action|steps|count" : "id|action|workflow|count")
                        if step.Has("steps")
                            this.Steps(raw, step["steps"], &total, depth+1)
                        else
                            this.Reference(raw, step["workflow"])
                        if step["action"] == "repeat"
                            this.Param(raw, step["count"], 1, 20, "Repeat count")
                    case "if":
                        if step.Has("condition") {
                            this.Keys(step, "id|action|condition|thenSteps|elseSteps")
                            this.Condition(raw, step["condition"])
                            this.Steps(raw, step["thenSteps"], &total, depth+1), this.Steps(raw, step["elseSteps"], &total, depth+1)
                        } else {
                            this.Keys(step, "id|action|target|then|otherwise"), this.Target(raw, step["target"])
                            for field in ["then", "otherwise"]
                                if step[field] != ""
                                    this.Reference(raw, step[field])
                        }
                    case "retry", "until":
                        this.Keys(step, step["action"] == "retry" ? "id|action|steps|condition|attempts|timeoutMs|intervalMs|failure" : "id|action|steps|condition|timeoutMs|intervalMs|failure")
                        this.Steps(raw, step["steps"], &total, depth+1), this.Condition(raw, step["condition"]), this.Failure(step["failure"])
                        this.Param(raw, step["timeoutMs"], 100, step["action"] == "retry" ? 60000 : 3600000, "Image-check timeout")
                        this.Param(raw, step["intervalMs"], 100, 10000, "Repeat interval")
                        if step["action"] == "retry"
                            this.Param(raw, step["attempts"], 1, 20, "Retry attempts")
                    default: throw ValueError("Unsupported workflow action.")
                }
        }
    }
    static Target(raw, id) {
        this.Id(id)
        if !raw["targets"].Has(id)
            throw ValueError("Missing target: " id)
    }
    static Reference(raw, id) {
        this.Id(id)
        if !raw["workflows"].Has(id)
            throw ValueError("Missing workflow: " id)
    }
    static Visit(raw, id, path, depth, done) {
        if depth > 8 || path.Has(id)
            throw ValueError("Workflow calls cannot be recursive or more than eight levels deep.")
        if done.Has(id) {
            if depth+done[id] > 8
                throw ValueError("Workflow calls cannot be more than eight levels deep.")
            return done[id]
        }
        path[id] := true
        height := this.VisitSteps(raw, raw["workflows"][id]["steps"], path, depth, done)
        path.Delete(id)
        done[id] := height
        return height
    }
    static VisitSteps(raw, steps, path, depth, done) {
        if depth > 8
            throw ValueError("Step and sequence nesting cannot exceed eight levels.")
        height := 0
        for step in steps {
            if step["action"] == "call" || (step["action"] == "repeat" && step.Has("workflow"))
                height := Max(height, 1+this.Visit(raw, step["workflow"], path, depth+1, done))
            else if step["action"] == "setting-call" {
                for option, workflow in step["routes"]
                    height := Max(height, 1+this.Visit(raw, workflow, path, depth+1, done))
            }
            else if step["action"] == "if" && !step.Has("condition")
                for field in ["then", "otherwise"]
                    if step[field] != ""
                        height := Max(height, 1+this.Visit(raw, step[field], path, depth+1, done))
            for field in ["steps", "thenSteps", "elseSteps"]
                if step.Has(field)
                    height := Max(height, 1+this.VisitSteps(raw, step[field], path, depth+1, done))
        }
        return height
    }
}
