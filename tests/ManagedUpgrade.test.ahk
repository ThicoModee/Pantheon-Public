#Requires AutoHotkey v2.0
#Include ..\Lib\framework\Runner.ahk

try {
    cfg := Map("panel", "panel", "affordable", "affordable", "max", "max", "closeX", 280, "closeY", 230, "progress", Map("x", 150, "y", 390, "width", 100, "height", 5), "intervalMs", 500, "settleMs", 100, "confirmMs", 500, "policy", "affordable")
    definition := JSON.parse(FileRead(A_ScriptDir "\data\flow-fixture.json", "UTF-8"))
    spec := cfg.Clone(), spec["panel"] := "popup-close", spec["affordable"] := "close-a", spec["max"] := "close-b"
    definition["targets"]["close-a"]["width"] := 200, definition["targets"]["close-a"]["height"] := 80
    definition["playback"] := Map("managedUpgrade", spec)
    FlowSchema.Validate(definition)
    bad := spec.Clone(), bad["closeX"] := 800, rejected := false
    try ManagedUpgrade.Config(bad, definition)
    catch Error
        rejected := true
    Assert(rejected, "off-client close coordinates are rejected")
    bad := spec.Clone(), bad["panel"] := "enter-confirm", rejected := false
    try ManagedUpgrade.Config(bad, definition)
    catch Error
        rejected := true
    Assert(rejected, "coordinate targets cannot replace managed-upgrade image checks")
    missing := cfg.Clone(), missing["affordable"] := "", message := ""
    try ManagedUpgrade.Config(missing)
    catch Error as err
        message := err.Message
    Assert(InStr(message, "Affordable upgrade button") && !InStr(message, "identifiers"), "missing image selection identifies the actual field")
    a := [], jitter := [], changed := []
    loop 64 {
        a.Push(0x202020), jitter.Push(0x303030), changed.Push(A_Index <= 8 ? 0xFFFFFF : 0x303030)
    }
    Assert(ManagedUpgrade.Stable(a, jitter) && !ManagedUpgrade.Changed(a, jitter), "small colour changes do not block or confirm an upgrade")
    Assert(ManagedUpgrade.Changed(a, changed) && !ManagedUpgrade.Stable(a, changed), "a significant upgrade-number change is detected")
    jitter[1] := 0xFFFFFF
    Assert(ManagedUpgrade.Stable(a, jitter) && !ManagedUpgrade.Changed(a, jitter), "one noisy pixel is ignored")
    ManagedUpgrade.Config(cfg)
    state := {Placement: Map("x", 400, "y", 300, "managedPriority", 1, "managedLimit", 1)}
    r := UpgradeFixture(), queue := ManagedUpgrade(r, cfg, Map("unit", state))
    queue.Tick()
    Assert(r.Presses == 1 && queue.Units[1]["confirmed"] == 1 && queue.Units[1]["done"], "upgrade requires stable visible progress before counting and respects its limit")
    Assert(r.Waits.Length == 2 && r.Waits[1] == 33 && r.Waits[2] == 33, "already-open panels and static progress avoid fixed settle delays")
    Assert(queue.Next == 0, "confirmed upgrades do not incur the unaffordable retry interval")
    Assert(!r.Environment.Panel && r.Environment.Closes == 1, "upgrade closes the panel before returning to result detection")
    queue.Next := 0, queue.Tick()
    Assert(r.Presses == 1, "completed unit is not upgraded again")
    r := UpgradeFixture(), r.Environment.Misses := 2
    queue := ManagedUpgrade(r, cfg, Map("unit", state)), queue.Tick()
    Assert(r.Environment.Selections.Length == 3 && r.Presses == 1 && !r.Environment.Panel, "missed unit selections retry before upgrading and still close the panel")
    r := UpgradeFixture(), r.Environment.Misses := 10, queue := ManagedUpgrade(r, cfg, Map("unit", state)), failed := false
    try queue.Tick()
    catch FlowImageError
        failed := true
    Assert(failed && r.Environment.Selections.Length == 3 && r.Presses == 0, "selection retries are bounded and never upgrade without a confirmed panel")
    r := UpgradeFixture(), r.Environment.Affordable := false
    queue := ManagedUpgrade(r, cfg, Map("unit", state)), queue.Tick()
    Assert(r.Presses == 0 && !r.Environment.Panel, "unaffordable unit is skipped and its panel closes")
    r := UpgradeFixture(), r.Environment.Maxed := true
    queue := ManagedUpgrade(r, cfg, Map("unit", state)), queue.Tick()
    Assert(r.Presses == 0 && queue.Units[1]["done"] && !r.Environment.Panel, "Max removes a unit without pressing upgrade")
    r := UpgradeFixture(), r.Confirm := false, queue := ManagedUpgrade(r, cfg, Map("unit", state)), failed := false
    try queue.Tick()
    catch FlowImageError
        failed := true
    Assert(failed && r.Presses == 1 && queue.Units[1]["confirmed"] == 0 && !r.Environment.Panel, "unconfirmed purchase stops rather than spamming upgrades and closes the panel")
    r := UpgradeFixture(), r.Environment.RefuseClose := true, queue := ManagedUpgrade(r, cfg, Map("unit", state)), failed := false
    try queue.Tick()
    catch FlowImageError
        failed := true
    Assert(failed, "failure to close the panel is reported")
    r := UpgradeFixture(), r.EndDuringUpgrade := true, queue := ManagedUpgrade(r, cfg, Map("unit", state))
    queue.Tick()
    Assert(r.Ended && !r.Environment.Panel && queue.Units[1]["confirmed"] == 0, "a match ending during an upgrade returns to result handling without a false purchase")
    high := {Placement: Map("x", 10, "y", 10, "managedPriority", 1, "managedLimit", 0)}, low := {Placement: Map("x", 20, "y", 20, "managedPriority", 5, "managedLimit", 0)}
    r := UpgradeFixture(), r.Environment.Affordable := false, cfg["policy"] := "save"
    queue := ManagedUpgrade(r, cfg, Map("low", low, "high", high)), queue.Tick(), queue.Next := 0, queue.Tick()
    Assert(r.Environment.Selections[1] == 10 && r.Environment.Selections[2] == 10, "save policy waits for the highest-priority unit")
    FileAppend("PASS: managed upgrade affordability, confirmed purchase, Max, per-unit limit, priority saving, result interruption and panel closure.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (" err.File ":" err.Line ")`n", "**")
    ExitApp(1)
}
ExitApp(0)
Assert(value, message) {
    if !value
        throw Error(message)
}
class UpgradeFixture {
    __New() {
        this.Environment := UpgradeEnvironment(), this.PlayKeys := Map("upgrade", "R"), this.Presses := 0, this.Confirm := true, this.EndDuringUpgrade := false, this.Waits := [], this.Ended := false, this.ResultTargets := ["victory", "defeat"]
    }
    Find(target, timeout) {
        if target == "victory" || target == "defeat"
            return this.Ended
        if !this.Environment.Panel
            return false
        return target == "panel" || (target == "affordable" && this.Environment.Affordable) || (target == "max" && this.Environment.Maxed)
    }
    Wait(ms) {
        this.Waits.Push(ms)
        Sleep(1)
    }
    Hold(keys, ms) {
        this.Presses++
        if this.EndDuringUpgrade
            this.Ended := true, this.Environment.Panel := false
        else if this.Confirm
            this.Environment.Version++
    }
}
class UpgradeEnvironment {
    __New() {
        this.Panel := false, this.Affordable := true, this.Maxed := false, this.Closes := 0, this.Version := 0, this.RefuseClose := false, this.Selections := [], this.Misses := 0
    }
    Click(x, y) {
        if x == 280 && y == 230 {
            this.Closes++
            if !this.RefuseClose
                this.Panel := false
        } else {
            this.Selections.Push(x)
            if this.Misses > 0
                this.Misses--
            else
                this.Panel := true
        }
    }
    Progress(rect) {
        samples := []
        loop 64
            samples.Push(this.Version ? 0xFFFFFF : 0x101010)
        return samples
    }
    Trace(*) {
    }
}
