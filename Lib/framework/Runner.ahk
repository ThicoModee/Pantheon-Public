#Requires AutoHotkey v2.0

#Include %A_LineFile%\..\Schema.ahk
#Include %A_LineFile%\..\WorkflowComponents.ahk



class FlowRunner {

    __New(definition, environment, values := unset) {

        this.Definition := FlowSchema.Validate(definition), this.Environment := environment

        this.Managed := 0, this.ResultTargets := []
        this.Cancelled := false, this.Budget := 100000, this.Started := 0, this.Deadlines := []

        this.Values := FlowSettings.Values(definition, IsSet(values) ? values : Map()), this.Context := Map(), this.PlacementData := 0, this.PlayKeys := PlayControls.Defaults()

    }

    Run(id) {

        FlowSchema.Reference(this.Definition, id)

        this.Managed := 0, this.ResultTargets := []
        this.Started := A_TickCount, this.Budget := 100000, this.Cancelled := false, this.Deadlines := []

        try {

            this.Check()

            this.Execute(id)

        }

        finally this.Environment.Release()

    }

    Cancel() => this.Cancelled := true

    Check() {

        if this.Cancelled

            throw Error("Workflow stopped.")

        if A_TickCount-this.Started > 7200000 || this.Budget < 1

            throw Error("Workflow execution limit reached.")

        for limit in this.Deadlines

            if A_TickCount >= limit.End

                throw FlowLoopTimeout(limit.Owner)

        this.Environment.Check()

        if this.Cancelled

            throw Error("Workflow stopped.")

    }

    Wait(milliseconds) {

        while milliseconds > 0 {

            this.Check()

            amount := Min(milliseconds, 50)

            this.Environment.Sleep(amount), milliseconds -= amount

        }

        this.Check()

    }

    Find(id, timeout) {

        started := A_TickCount

        loop {

            this.Check()

            found := this.Environment.Find(this.Definition["targets"][id])

            if found

                return found

            if A_TickCount-started >= timeout

                return 0

            this.Wait(100)

        }

    }

    Execute(id) {

        this.ExecuteSteps(this.Definition["workflows"][id]["steps"], id)

    }

    Condition(condition) {

        all := condition["operator"] == "all"

        for check in condition["checks"] {

            this.Budget--, this.Check()

            if check.Has("operator")

                matched := this.Condition(check)

            else if check.Has("selectedImage") {

                spec := FlowSettings.Spec(this.Definition, check["selectedImage"])

                target := FlowSettings.Option(spec, this.Values[check["selectedImage"]])["target"]

                matched := !!this.Find(target, 0)

                if check["state"] == "absent"

                    matched := !matched

            } else if check.Has("setting")

                matched := FlowSettings.Match(this.Values, check)

            else {

                matched := !!this.Find(check["target"], 0)

                if check["state"] == "absent"

                    matched := !matched

            }

            if all && !matched

                return false

            if !all && matched

                return true

        }

        return all

    }

    WaitCondition(condition, timeout) {

        started := A_TickCount

        loop {

            if this.Condition(condition)

                return true

            if A_TickCount-started >= timeout

                return false

            this.Wait(Min(200, timeout-(A_TickCount-started)))

        }

    }

    Hold(keys, duration) {

        pressed := []

        try {

            for key in keys {

                this.Check(), this.Environment.Key(key, true)

                pressed.Push(key)

            }

            this.Wait(duration)

        } finally {

            loop pressed.Length

                this.Environment.Key(pressed[pressed.Length-A_Index+1], false)

        }

    }

    Until(step, location) {

        matched := false

        this.Deadlines.Push({End: A_TickCount+step["timeoutMs"], Owner: location})

        try {

            loop {

                this.Budget--, this.Check()

                if this.Condition(step["condition"]) {

                    this.Check(), matched := true

                    break

                }

                this.ExecuteSteps(step["steps"], location)

                this.Wait(step["intervalMs"])

            }

        } catch Error as err {

            if !(err is FlowLoopTimeout) || err.Owner != location

                throw err

        } finally this.Deadlines.Pop()

        if !matched && step["failure"] == "error"

            throw FlowImageError("Image loop timed out (" location ").")

    }

    Camera(step) {
        this.Environment.Move(400, 300)
        loop step["zoomIn"] {
            this.Check(), this.Environment.Scroll("Up", 1), this.Wait(50)
        }
        this.Wait(200)
        try {
            this.Environment.Key("RButton", true)
            this.Wait(100)
            loop 10 {
                this.Check(), this.Environment.Move(400, 300+Floor(step["tilt"]*A_Index/10)), this.Wait(20)
            }
        } finally this.Environment.Key("RButton", false)
        loop step["zoomOut"] {
            this.Check(), this.Environment.Scroll("Down", 1), this.Wait(50)
        }
    }
    ResultImages(steps, result) {
        for step in steps {
            if step["action"] == "outcome" {
                for field in ["victory", "defeat"]
                    if !result.Has(step[field])
                        result[step[field]] := true
            }
            for field in ["steps", "thenSteps", "elseSteps"]
                if step.Has(field)
                    this.ResultImages(step[field], result)
        }
    }
    Placements(step) {
        if !this.PlacementData
            throw Error("No placement setup was supplied. Save a setup in Placement setup first.")
        cfg := PlacementPlan.Config(this.Definition.Get("playback", Map()))
        plan := PlacementPlan.Validate(this.PlacementData, true, cfg)
        id := step["route"] == "selected" ? plan["selectedRoute"] : step["route"]
        if step["route"] == "setting"
            id := FlowSettings.Option(FlowSettings.Spec(this.Definition, step["setting"]), this.Values[step["setting"]])["map"]
        if plan.Get("useShared", 0)
            id := "shared"
        selected := 0, shared := 0
        for route in plan["routes"] {
            if route["id"] == id
                selected := route
            if route["id"] == "shared"
                shared := route
        }
        if (!selected || !this.HasPlacements(selected)) && step["fallback"] == "shared"
            selected := shared
        if !selected || !this.HasPlacements(selected)
            throw Error("No unit placements configured for " id ".")
        for action in selected["teams"][selected["team"]]["steps"]
            if action["kind"] == "start" && action["enabled"] && action["x"] == 0 && action["y"] == 0
                throw Error("Set Start Game coordinates in Placement setup, or disable it if the game starts automatically.")
        this.Environment.Trace("Placement setup", selected["name"], "Team " selected["team"])
        live := Map(), skipped := Map(), results := Map()
        for id, flow in this.Definition["workflows"]
            this.ResultImages(flow["steps"], results)
        this.ResultTargets := []
        for target in results
            this.ResultTargets.Push(target)
        for action in selected["teams"][selected["team"]]["steps"] {
            this.Budget--, this.Check()
            if !action["enabled"]
                continue
            kind := action["kind"]
            if (kind == "upgrade" || kind == "sell" || kind == "reconfigure") && skipped.Has(action["placement"]) {
                this.Environment.Trace("Match action skipped", action["id"], "Its placement was skipped")
                continue
            }
            this.Wait(action["delayMs"])
            if kind == "wait"
                continue
            if kind == "place" {
                if cfg.Has("placementFeedback") {
                    result := PlacementFeedback.Place(this, action, cfg["placementFeedback"])
                    if result == -1
                        break
                    if !result {
                        skipped[action["id"]] := true
                        continue
                    }
                } else {
                    this.Hold([this.PlayKeys["slot-" action["slot"]]], 30), this.Wait(150)
                    this.Environment.Click(action["x"], action["y"]), this.Wait(150)
                    this.Hold([this.PlayKeys["cancel"]], 30)
                }
                live[action["id"]] := {Targeting: 0, Auto: 0, Placement: action}
                if action["targeting"] > 0 || action["autoUpgrade"] > 0 {
                    this.Environment.Click(action["x"], action["y"]), this.Wait(150)
                    this.ConfigurePlacement(live[action["id"]], action, cfg, true)
                }
            } else if kind == "start" {
                this.Environment.Click(action["x"], action["y"])
                this.Wait(300)
            } else {
                if !live.Has(action["placement"])
                    throw Error("The linked unit has not been placed, or was already sold.")
                state := live[action["placement"]], target := state.Placement
                this.Environment.Click(target["x"], target["y"]), this.Wait(150)
                if kind == "reconfigure"
                    this.ConfigurePlacement(state, action, cfg)
                else if kind == "sell" {
                    this.Hold([this.PlayKeys["sell"]], 30), this.Wait(200)
                    live.Delete(action["placement"])
                } else {
                    loop action["repeat"] {
                        this.Hold([this.PlayKeys["upgrade"]], 30), this.Wait(200)
                    }
                }
            }
        }
        this.Managed := cfg.Has("managedUpgrade") ? ManagedUpgrade(this, cfg["managedUpgrade"], live) : 0
    }
    Outcome(step, location) {
        this.ResultTargets := [step["victory"], step["defeat"]]
        this.Deadlines.Push({End: A_TickCount+step["timeoutMs"], Owner: location})
        won := false
        try {
            if this.Managed
                this.Managed.Close()
            loop {
                this.Check()
                won := this.Find(step["victory"], 0)
                lost := !won && this.Find(step["defeat"], 0)
                if won || lost
                    break
                if this.Managed
                    this.Managed.Tick()
                this.Wait(this.Managed ? 25 : 200)
            }
        } catch FlowLoopTimeout as err {
            if err.Owner != location
                throw err
            throw FlowImageError("Match result was not detected before the timeout.")
        } finally this.Deadlines.Pop()
        this.Managed := 0
        if HasMethod(this.Environment, "Result")
            this.Environment.Result(!!won)
        this.ExecuteSteps(won ? step["thenSteps"] : step["elseSteps"], location)
    }
    ConfigurePlacement(state, action, cfg, placing := false) {
        if placing || action["changeTargeting"] {
            desired := action["targeting"], count := cfg["targeting"].Length
            presses := Mod(desired-state.Targeting+count, count)
            loop presses {
                this.Hold([this.PlayKeys["targeting"]], 30), this.Wait(150)
                state.Targeting := Mod(state.Targeting+1, count)
            }
        }
        desired := action["autoUpgrade"]
        if desired < 0
            return
        if !cfg["autoUpgrade"] {
            if desired > 0
                throw Error("This macro does not support auto upgrade.")
            return
        }
        count := cfg["autoUpgradeLevels"]+1
        presses := Mod(desired-state.Auto+count, count)
        loop presses {
            this.Hold([this.PlayKeys["auto-upgrade"]], 30), this.Wait(150)
            state.Auto := Mod(state.Auto+1, count)
        }
    }
    HasPlacements(route) {
        for action in route["teams"][route["team"]]["steps"]
            if action["kind"] == "place" && action.Get("enabled", 1)
                return true
        return false
    }
    ExecuteSteps(steps, context) {

        for step in steps {

            step := step.Clone()

            for field in ["x", "y", "durationMs", "timeoutMs", "intervalMs", "count", "ticks", "attempts", "maxScrolls", "sprint"]

                if step.Has(field) && step[field] is Map

                    step[field] := this.Values[step[field]["setting"]]

            this.Budget--, this.Check()

            location := context " / " step["id"]

            stepName := step.Get("name", "")
            this.Environment.Trace(context, stepName == "" ? step["id"] : stepName, step["action"])

            switch step["action"] {

                case "camera": this.Camera(step)
                case "placements": this.Placements(step)
                case "stop": throw FlowStop("Macro stopped by its sequence.")

                case "delay": this.Wait(step["durationMs"])

                case "key": this.Hold([step["key"]], step["durationMs"])

                case "press":

                    loop step["count"] {

                        this.Hold([step["key"]], 30)

                        if A_Index < step["count"]

                            this.Wait(step["intervalMs"])

                    }

                case "walk":

                    keys := step["keys"].Clone()

                    if step["sprint"]

                        keys.InsertAt(1, step["sprintKey"])

                    this.Hold(keys, step["durationMs"])

                case "click-point": this.Environment.Click(step["x"], step["y"], step["button"])

                case "move": this.Environment.Move(step["x"], step["y"])

                case "scroll":

                    loop step["count"] {

                        this.Check(), this.Environment.Scroll(step["direction"], step["ticks"])

                        this.Wait(step["intervalMs"])

                    }

                case "click", "wait", "click-setting":

                    if step["action"] == "click-setting" {

                        setting := step["setting"], value := this.Context.Get(setting, this.Values[setting])

                        if value is Array

                            throw Error("Use 'For each selected item' around a list-setting click.")

                        step["target"] := FlowSettings.Option(FlowSettings.Spec(this.Definition, setting), value)["target"]

                    }

                    found := step.Has("condition") ? this.WaitCondition(step["condition"], step["timeoutMs"]) : this.Find(step["target"], step["timeoutMs"])

                    if !found && step["missing"] == "error"

                        throw FlowImageError("Image check failed: " step.Get("target", "condition") " (" location ").")

                    if found && step["action"] != "wait" {

                        this.Check()

                        if step.Has("button")

                            this.Environment.Click(found["x"], found["y"], step["button"])

                        else

                            this.Environment.Click(found["x"], found["y"])

                    }

                case "call": this.Execute(step["workflow"])

                case "for-setting":

                    setting := step["setting"], existed := this.Context.Has(setting), previous := this.Context.Get(setting, "")

                    try {

                        for value in this.Values[setting] {

                            this.Budget--, this.Check(), this.Context[setting] := value

                            this.ExecuteSteps(step["steps"], location)

                        }

                    } finally {

                        if existed

                            this.Context[setting] := previous

                        else if this.Context.Has(setting)

                            this.Context.Delete(setting)

                    }

                case "repeat":

                    loop step["count"]

                        if step.Has("steps")

                            this.ExecuteSteps(step["steps"], location)

                        else

                            this.Execute(step["workflow"])

                case "click-wait", "scroll-option", "dismiss", "setting-call": WorkflowComponents.Execute(this, step, location)
                case "outcome": this.Outcome(step, location)
                case "if":

                    if step.Has("condition")

                        this.ExecuteSteps(this.Condition(step["condition"]) ? step["thenSteps"] : step["elseSteps"], location)

                    else {

                        branch := this.Find(step["target"], 0) ? step["then"] : step["otherwise"]

                        if branch != ""

                            this.Execute(branch)

                    }

                case "retry":

                    matched := false

                    loop step["attempts"] {

                        this.Budget--, this.Check()

                        try {

                            this.ExecuteSteps(step["steps"], location)

                            matched := this.WaitCondition(step["condition"], step["timeoutMs"])

                        } catch Error as err {

                            if !(err is FlowImageError)

                                throw err

                            matched := false

                        }

                        if matched

                            break

                        if A_Index < step["attempts"]

                            this.Wait(step["intervalMs"])

                    }

                    if !matched && step["failure"] == "error"

                        throw FlowImageError("Retry limit reached (" location ").")

                case "until": this.Until(step, location)

            }

        }

    }

}
