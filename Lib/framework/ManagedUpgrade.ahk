#Requires AutoHotkey v2.0

class ManagedUpgrade {
    static Config(raw, definition := unset) {
        raw := raw.Clone()
        for field in ["pathColor", "pathTolerance", "pathRadius", "pathClearance", "pathAttempts", "placementConfirmMs"]
            if raw.Has(field)
                raw.Delete(field)
        FlowSchema.Keys(raw, "panel|affordable|max|closeX|closeY|progress|intervalMs|settleMs|confirmMs|policy")
        labels := Map("panel", "Selected unit panel", "affordable", "Affordable upgrade button", "max", "Max upgrade")
        for field in ["panel", "affordable", "max"] {
            if !raw.Has(field) || !(raw[field] is String) || !RegExMatch(raw[field], "^[a-z][a-z0-9-]{0,47}$")
                throw ValueError("Select a captured image for Managed upgrades: " labels[field] ".")
            if IsSet(definition) {
                if !definition["targets"].Has(raw[field]) || definition["targets"][raw[field]]["kind"] != "pattern"
                    throw ValueError("Select an existing captured image for Managed upgrades: " labels[field] ".")
            }
        }
        if IsSet(definition) {
            area := definition["targets"][raw["affordable"]]
            if area["width"] == 800 && area["height"] == 600
                throw ValueError("Restrict the Affordable upgrade button target to its button area using Search captured area only.")
        }
        if raw["panel"] == raw["affordable"] || raw["panel"] == raw["max"] || raw["max"] == raw["affordable"]
            throw ValueError("Use different managed-upgrade images for panel, affordable and Max.")
        FlowSchema.Int(raw["closeX"], 0, 799, "Close panel X"), FlowSchema.Int(raw["closeY"], 0, 599, "Close panel Y")
        rect := raw["progress"]
        FlowSchema.Keys(rect, "x|y|width|height")
        FlowSchema.Int(rect["x"], 0, 799, "Progress X"), FlowSchema.Int(rect["y"], 0, 599, "Progress Y")
        FlowSchema.Int(rect["width"], 1, Min(200, 800-rect["x"]), "Progress width")
        FlowSchema.Int(rect["height"], 1, Min(80, 600-rect["y"]), "Progress height")
        FlowSchema.Int(raw["intervalMs"], 500, 10000, "Upgrade interval")
        FlowSchema.Int(raw["settleMs"], 100, 2000, "Panel settle time")
        FlowSchema.Int(raw["confirmMs"], 500, 10000, "Upgrade confirmation timeout")
        FlowSchema.Enum(raw["policy"], ["affordable", "save"], "upgrade policy")
        return raw
    }
    __New(runner, config, live) {
        this.Runner := runner, this.ConfigData := config, this.Units := [], this.Next := 0, this.Index := 1
        loop 10 {
            priority := A_Index
            for id, state in live
                if state.Placement["managedPriority"] == priority
                    this.Units.Push(Map("id", id, "state", state, "done", false, "confirmed", 0))
        }
    }
    Close() {
        r := this.Runner, c := this.ConfigData
        if !r.Find(c["panel"], 0)
            return
        r.Environment.Click(c["closeX"], c["closeY"])
        if !this.WaitPanel(false)
            throw FlowImageError("Could not close the unit panel before checking match results.")
    }
    WaitPanel(present) {
        r := this.Runner, started := A_TickCount
        loop {
            if !!r.Find(this.ConfigData["panel"], 0) == present
                return true
            remaining := this.ConfigData["settleMs"]-(A_TickCount-started)
            if remaining <= 0
                return false
            r.Wait(Min(50, remaining))
        }
    }
    static Difference(a, b) {
        if !(a is Array) || !(b is Array) || !a.Length || a.Length != b.Length
            throw FlowImageError("Could not sample the upgrade progress region.")
        changed := 0
        for i, pixel in a {
            other := b[i]
            if Abs(((pixel >> 16) & 255)-((other >> 16) & 255)) > 32
                || Abs(((pixel >> 8) & 255)-((other >> 8) & 255)) > 32
                || Abs((pixel & 255)-(other & 255)) > 32
                changed++
        }
        return changed
    }
    static Stable(a, b) => this.Difference(a, b) <= Max(1, Floor(a.Length*0.01))
    static Changed(a, b) => this.Difference(a, b) >= Max(2, Ceil(a.Length*0.02))
    ResultVisible() {
        for target in this.Runner.ResultTargets
            if this.Runner.Find(target, 0)
                return true
        return false
    }
    Tick() {
        try this.CheckUnit()
        catch FlowImageError as err {
            if !this.ResultVisible()
                throw err
        }
    }
    CheckUnit() {
        r := this.Runner, c := this.ConfigData
        if !this.Units.Length || A_TickCount < this.Next
            return
        this.Next := A_TickCount+c["intervalMs"]
        selected := 0
        loop this.Units.Length {
            if this.Index > this.Units.Length
                this.Index := 1
            item := this.Units[this.Index]
            this.Index++
            if !item["done"] {
                selected := item
                break
            }
        }
        if !selected
            return
        p := selected["state"].Placement
        try {
            opened := false
            loop 3 {
                if this.ResultVisible()
                    return
                if r.Find(c["panel"], 0) {
                    opened := true
                    break
                }
                r.Environment.Click(p["x"], p["y"])
                if this.WaitPanel(true) {
                    opened := true
                    break
                }
                r.Wait(200)
            }
            if !opened {
                if this.ResultVisible()
                    return
                throw FlowImageError("Managed upgrade could not open the selected unit panel after 3 clicks. Check its placement coordinate and panel image.")
            }
            if r.Find(c["max"], 0) {
                selected["done"] := true
                this.Next := 0
                return
            }
            if !r.Find(c["affordable"], 0) {
                if c["policy"] == "save"
                    this.Index--
                return
            }
            before := r.Environment.Progress(c["progress"])
            r.Hold([r.PlayKeys["upgrade"]], 40)
            started := A_TickCount, confirmed := false
            loop {
                r.Wait(33)
                if !r.Find(c["panel"], 0)
                    break
                if r.Find(c["max"], 0) {
                    selected["done"] := true, confirmed := true
                    break
                }
                after := r.Environment.Progress(c["progress"])
                if ManagedUpgrade.Changed(before, after) {
                    r.Wait(33)
                    if r.Find(c["panel"], 0) {
                        settled := r.Environment.Progress(c["progress"])
                        if ManagedUpgrade.Stable(after, settled) && ManagedUpgrade.Changed(before, settled) {
                            confirmed := true
                            break
                        }
                    }
                }
                if A_TickCount-started >= c["confirmMs"]
                    break
            }
            if !confirmed
                throw FlowImageError("Upgrade was not confirmed. Check the upgrade key and progress capture before retrying.")
            this.Next := 0
            selected["confirmed"]++
            if p["managedLimit"] && selected["confirmed"] >= p["managedLimit"]
                selected["done"] := true
            r.Environment.Trace("Managed upgrade", selected["id"], "Confirmed upgrade " selected["confirmed"])
            if c["policy"] == "save" && !selected["done"]
                this.Index--
        } finally this.Close()
    }
}
