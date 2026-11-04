#Requires AutoHotkey v2.0

class PlacementFeedback {
    static Config(raw, definition := unset) {
        FlowSchema.Keys(raw, "panel|money|limit|unique|closeX|closeY|retryMs|observeMs")
        labels := Map("panel", "Selected unit panel", "money", "Not enough money", "limit", "Placement limit", "unique", "Unique-unit conflict")
        for field in ["panel", "money", "limit", "unique"] {
            value := raw.Get(field, "")
            if value == "" && (field == "limit" || field == "unique")
                continue
            if !(value is String) || !RegExMatch(value, "^[a-z][a-z0-9-]{0,47}$")
                throw ValueError("Select a captured image for Placement feedback: " labels[field] ".")
            if IsSet(definition) && (!definition["targets"].Has(value) || definition["targets"][value]["kind"] != "pattern")
                throw ValueError("Select an existing image for Placement feedback: " labels[field] ".")
        }
        seen := Map()
        for field in ["panel", "money", "limit", "unique"] {
            value := raw.Get(field, "")
            if value == ""
                continue
            if seen.Has(value)
                throw ValueError("Use different images for each Placement feedback message and the unit panel.")
            seen[value] := true
        }
        FlowSchema.Int(raw["closeX"], 0, 799, "Close panel X"), FlowSchema.Int(raw["closeY"], 0, 599, "Close panel Y")
        FlowSchema.Int(raw["retryMs"], 250, 5000, "Placement retry interval")
        FlowSchema.Int(raw["observeMs"], 100, 3000, "Placement response timeout")
        return raw
    }
    static Check(r, deadline) {
        r.Check()
        if A_TickCount >= deadline
            throw FlowImageError("Placement timed out while waiting for money or confirmation. Increase this Place action's timeout or check its feedback images.")
    }
    static Ended(r) {
        for target in r.ResultTargets
            if r.Find(target, 0)
                return true
        return false
    }
    static Message(r, c) {
        for field in ["limit", "unique", "money"]
            if c.Get(field, "") != "" && r.Find(c[field], 0)
                return field
        return ""
    }
    static Close(r, c) {
        if !r.Find(c["panel"], 0)
            return
        r.Environment.Click(c["closeX"], c["closeY"])
        started := A_TickCount
        while r.Find(c["panel"], 0) {
            if A_TickCount-started >= c["observeMs"]
                throw FlowImageError("Could not close the unit panel during placement feedback handling.")
            r.Wait(50)
        }
    }
    static Observe(r, c, deadline, messages := true) {
        started := A_TickCount
        loop {
            this.Check(r, deadline)
            if this.Ended(r)
                return "ended"
            if r.Find(c["panel"], 0)
                return "placed"
            if messages && (found := this.Message(r, c))
                return found
            if A_TickCount-started >= c["observeMs"]
                return ""
            r.Wait(50)
        }
    }
    static Place(r, action, c) {
        deadline := A_TickCount+action["timeoutMs"]
        try {
            r.Hold([r.PlayKeys["cancel"]], 30)
            this.Close(r, c)
            loop {
                this.Check(r, deadline)
                if this.Ended(r)
                    return -1
                while this.Message(r, c) != "" {
                    this.Check(r, deadline)
                    if this.Ended(r)
                        return -1
                    r.Wait(50)
                }
                r.Hold([r.PlayKeys["slot-" action["slot"]]], 30)
                r.Wait(100)
                r.Environment.Click(action["x"], action["y"])
                result := this.Observe(r, c, deadline)
                r.Hold([r.PlayKeys["cancel"]], 30)
                if result == "ended"
                    return -1
                if result == "placed"
                    return 1
                if result == "limit" || result == "unique" {
                    r.Environment.Trace("Placement skipped", action["id"], result == "limit" ? "Placement limit reached" : "Unique-unit conflict")
                    return 0
                }
                r.Environment.Click(action["x"], action["y"])
                inspected := this.Observe(r, c, deadline, false)
                if inspected == "placed"
                    return 1
                if inspected == "ended"
                    return -1
                if result != "money"
                    throw FlowImageError("Placement could not be confirmed and no money or limit message was detected. Check the panel image and saved coordinate.")
                r.Environment.Trace("Placement waiting", action["id"], "Not enough money; retrying")
                r.Wait(c["retryMs"])
            }
        } finally {
            try r.Hold([r.PlayKeys["cancel"]], 30)
            finally this.Close(r, c)
        }
    }
}
