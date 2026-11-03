#Requires AutoHotkey v2.0
#Include ..\Lib\HubModel.ahk
#Include ..\Lib\Desktop.ahk
#Include ..\Lib\framework\Runner.ahk

try {
    d := Map("version", 1, "name", "Linked placement fixture", "game", "fixture-td", "mode", "custom", "entry", "main", "client", Map("width", 800, "height", 600), "targets", Map(), "settings", Map(),
        "playback", Map("autoUpgrade", 1, "autoUpgradeLevels", 3, "targeting", ["First", "Last", "Strongest", "Weakest"]),
        "workflows", Map("main", Map("name", "Main", "steps", [Map("id", "play", "action", "placements", "route", "shared", "fallback", "error")])))
    start := PlacementStore.Step(), start["x"] := 350, start["y"] := 100
    first := Action("place", "first", 3, 63, 334), first["targeting"] := 2, first["autoUpgrade"] := 2
    second := Action("place", "second", 3, 140, 250)
    upgrade := Action("upgrade", "upgrade", 3, 0, 0), upgrade["placement"] := "first", upgrade["repeat"] := 3
    reconfigure := Action("reconfigure", "config", 3, 0, 0), reconfigure["placement"] := "first", reconfigure["targeting"] := 1, reconfigure["autoUpgrade"] := 1
    unchanged := Action("reconfigure", "unchanged", 3, 0, 0), unchanged["placement"] := "first", unchanged["changeTargeting"] := 0, unchanged["autoUpgrade"] := -1
    sell := Action("sell", "sell", 3, 0, 0), sell["placement"] := "second"
    plan := PlacementStore.Defaults(), plan["routes"][1]["teams"][1]["steps"] := [start, first, second, upgrade, reconfigure, unchanged, sell]
    validated := PlacementPlan.Validate(plan, true, d["playback"])
    Assert(validated["routes"][1]["teams"][1]["steps"][4]["x"] == 63, "upgrade resolves its placement coordinate")
    first["x"] := 180, first["y"] := 420
    env := LinkedFixture(), runner := FlowRunner(d, env), runner.PlacementData := plan
    runner.Run("main")
    Assert(env.Keys.Get("R", 0) == 3, "manual upgrade presses preserved with auto upgrade enabled")
    Assert(env.Keys.Get("T", 0) == 5 && env.Keys.Get("K", 0) == 5, "targeting and auto upgrade cycle forward from remembered states")
    Assert(env.Keys.Get("X", 0) == 1 && env.Held.Count == 0, "sell uses one key press and releases all input")
    Assert(env.Clicks[5][1] == 180 && env.Clicks[5][2] == 420, "upgrade follows the moved placement instead of stale coordinates")
    Assert(env.Clicks[-1][1] == 140, "sell selects the other instance of the same slot")
    noAuto := Clone(d), noAuto["playback"]["autoUpgrade"] := 0
    Reject(plan, noAuto["playback"], "auto upgrade requests rejected for unsupported games")
    manual := Clone(plan), steps := manual["routes"][1]["teams"][1]["steps"]
    steps.RemoveAt(7), steps.RemoveAt(6), steps.RemoveAt(5), steps[2]["autoUpgrade"] := 0, steps[2]["targeting"] := 0
    env := LinkedFixture(), runner := FlowRunner(noAuto, env), runner.PlacementData := manual
    runner.Run("main")
    Assert(env.Keys.Get("R", 0) == 3 && !env.Keys.Has("K"), "manual-only games never receive auto upgrade inputs")
    disabled := Clone(manual), disabled["routes"][1]["teams"][1]["steps"][1]["enabled"] := 0
    disabled["routes"][1]["teams"][1]["steps"][1]["x"] := 0, disabled["routes"][1]["teams"][1]["steps"][1]["y"] := 0
    env := LinkedFixture(), runner := FlowRunner(noAuto, env), runner.PlacementData := disabled
    runner.Run("main")
    Assert(env.Clicks.Length == 3 && env.Clicks[1][1] == 180, "disabled Start Game skips its click and coordinate requirement")
    bad := Clone(plan), bad["routes"][1]["teams"][1]["steps"][4]["placement"] := "missing"
    Reject(bad, d["playback"], "dangling placement references rejected")
    bad := Clone(plan), list := bad["routes"][1]["teams"][1]["steps"], list.Push(Clone(upgrade))
    list[-1]["id"] := "after-sale", list[-1]["placement"] := "second"
    Reject(bad, d["playback"], "sold units cannot be reused")
    legacy := Clone(manual), legacy["routes"][1]["teams"][1]["steps"][4].Delete("placement")
    legacy["routes"][1]["teams"][1]["steps"][4]["x"] := 180, legacy["routes"][1]["teams"][1]["steps"][4]["y"] := 420
    Assert(PlacementPlan.Validate(legacy, true)["routes"][1]["teams"][1]["steps"][4]["placement"] == "first", "unique legacy coordinate actions migrate to IDs")
    FileAppend("PASS: persistent placement references, moved coordinates, multiple instances, manual-only games, remembered forward targeting/auto cycles, no-change state, invalid and sold references, legacy migration.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (" err.File ":" err.Line ")`n", "**")
    ExitApp(1)
}
ExitApp(0)
Action(kind, id, slot, x, y) {
    action := PlacementStore.Step(), action["kind"] := kind, action["id"] := id, action["slot"] := slot, action["x"] := x, action["y"] := y
    return action
}
Clone(value) => JSON.parse(JSON.stringify(value))
Assert(value, message) {
    if !value
        throw Error(message)
}
Reject(plan, cfg, message) {
    rejected := false
    try PlacementPlan.Validate(plan, true, cfg)
    catch Error
        rejected := true
    Assert(rejected, message)
}
class LinkedFixture {
    __New() {
        this.Keys := Map(), this.Clicks := [], this.Held := Map()
    }
    Check() {
    }
    Click(x, y) => this.Clicks.Push([x, y])
    Key(key, down) {
        if down {
            this.Keys[key] := this.Keys.Get(key, 0)+1
            this.Held[key] := true
        } else if this.Held.Has(key)
            this.Held.Delete(key)
    }
    Sleep(ms) {
    }
    Trace(args*) {
    }
    Release() => this.Held := Map()
}
