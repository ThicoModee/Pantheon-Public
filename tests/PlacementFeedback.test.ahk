#Requires AutoHotkey v2.0
#Include ..\Lib\framework\Runner.ahk

try {
    d := JSON.parse(FileRead(A_ScriptDir "\data\flow-fixture.json", "UTF-8"))
    pattern := d["targets"]["popup-close"].Clone()
    for name in ["panel", "money", "limit", "unique"] {
        target := pattern.Clone(), target["name"] := name
        d["targets"][name] := target
    }
    cfg := Map("panel", "panel", "money", "money", "limit", "limit", "unique", "unique", "closeX", 280, "closeY", 230, "retryMs", 250, "observeMs", 100)
    d["playback"] := Map("placementFeedback", cfg)
    d["workflows"] := Map("main", Map("name", "Main", "steps", [Map("id", "play", "action", "placements", "route", "shared", "fallback", "error")]))
    d["entry"] := "main"
    FlowSchema.Validate(d)
    action := Map("id", "unit", "slot", 1, "x", 400, "y", 300, "timeoutMs", 1500)
    env := FeedbackEnvironment(), r := FlowRunner(d, env), r.Started := A_TickCount
    result := PlacementFeedback.Place(r, action, cfg)
    Assert(result == 1 && env.Attempts == 2 && env.Placed == 1 && env.Inspections == 1 && !env.Selected && !env.Panel, "money failure retries once after inspecting the attempted point and clearing its old message")
    env := FeedbackEnvironment(), env.Failures := 0, env.AutoPanel := false, r := FlowRunner(d, env), r.Started := A_TickCount
    result := PlacementFeedback.Place(r, action, cfg)
    Assert(result == 1 && env.Placed == 1 && env.Attempts == 1 && env.Inspections == 1, "reselecting a placed unit confirms success without a second placement")
    for message in ["limit", "unique"] {
        env := FeedbackEnvironment(), env.Permanent := message, r := FlowRunner(d, env), r.Started := A_TickCount
        Assert(PlacementFeedback.Place(r, action, cfg) == 0 && env.Attempts == 1 && !env.Selected, "permanent placement restriction skips without retrying")
    }
    env := FeedbackEnvironment(), env.Failures := 999, r := FlowRunner(d, env), r.Started := A_TickCount, failed := false
    action["timeoutMs"] := 400
    try PlacementFeedback.Place(r, action, cfg)
    catch FlowImageError as err
        failed := InStr(err.Message, "timed out") > 0
    Assert(failed && env.Placed == 0 && !env.Selected, "money retries are bounded and release placement mode on timeout")
    start := Map("id", "start-game", "kind", "start", "enabled", 0, "slot", 1, "x", 0, "y", 0, "delayMs", 0, "repeat", 1, "timeoutMs", 30000)
    place := start.Clone(), place["id"] := "unit", place["kind"] := "place", place["enabled"] := 1, place["x"] := 400, place["y"] := 300
    upgrade := place.Clone(), upgrade["id"] := "upgrade", upgrade["kind"] := "upgrade", upgrade["placement"] := "unit", upgrade["delayMs"] := 600000
    plan := Map("version", 1, "selectedRoute", "shared", "routes", [Map("id", "shared", "name", "Shared", "team", 1, "teams", [])])
    loop 8
        plan["routes"][1]["teams"].Push(Map("steps", A_Index == 1 ? [start, place, upgrade] : [start.Clone()]))
    env := FeedbackEnvironment(), env.Permanent := "limit", r := FlowRunner(d, env), r.PlacementData := plan
    r.Run("main")
    Assert(env.UpgradeKeys == 0 && InStr(env.Log, "Its placement was skipped"), "linked upgrades are skipped when their unit cannot be placed")
    FileAppend("PASS: money retries, stale-message clearing, existing-unit inspection, permanent skips, timeout cleanup and linked-action exclusion.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (" err.File ":" err.Line ")`n", "**")
    ExitApp(1)
}
ExitApp(0)
Assert(value, message) {
    if !value
        throw Error(message)
}
class FeedbackEnvironment {
    __New() {
        this.Selected := false, this.Panel := false, this.Attempts := 0, this.Placed := 0, this.Failures := 1, this.AutoPanel := true, this.MoneyTicks := 0, this.Permanent := "", this.Inspections := 0, this.UpgradeKeys := 0, this.Log := ""
    }
    Check() {
    }
    Find(target) {
        name := target["name"]
        if name == "panel"
            return this.Panel ? Map("x", 0, "y", 0) : 0
        if name == "money" && this.MoneyTicks > 0 {
            this.MoneyTicks--
            return Map("x", 0, "y", 0)
        }
        if name == this.Permanent && this.Attempts > 0
            return Map("x", 0, "y", 0)
        return 0
    }
    Click(x, y) {
        if x == 280 && y == 230 {
            this.Panel := false
            return
        }
        if this.Selected {
            this.Attempts++
            if this.Permanent != ""
                return
            if this.Attempts <= this.Failures
                this.MoneyTicks := 3
            else
                this.Placed++, this.Panel := this.AutoPanel
        } else {
            this.Inspections++
            if this.Placed
                this.Panel := true
        }
    }
    Key(key, down) {
        if !down
            return
        if key == "Q"
            this.Selected := false
        else if key == "1"
            this.Selected := true
        else if key == "R"
            this.UpgradeKeys++
    }
    Sleep(ms) => Sleep(1)
    Trace(flow, step, action) => this.Log .= action "`n"
    Release() => this.Selected := false
}
