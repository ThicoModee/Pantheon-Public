#Requires AutoHotkey v2.0
#Include ..\Lib\HubModel.ahk
#Include ..\Lib\Desktop.ahk
#Include ..\Lib\framework\Runner.ahk

try {
    MacroPackages.Root := A_ScriptDir "\..\test-results\shared-play-" A_TickCount
    MacroPackages.Bundled := MacroPackages.Root "\supplied"
    PlacementStore.Root := MacroPackages.Root "\placements"
    MacroPackages.Cached := 0, MacroHub.Config["developer"] := 1
    first := MacroPackages.New(), d := first["definition"]
    d["game"] := "shared-test-game"
    d["maps"] := Map("test-map", Map("name", "Test map"))
    d["settings"] := Map("upgrade-key", Map("label", "Upgrade", "type", "select", "default", "key-t", "options", [Map("value", "key-t", "label", "T", "target", "")]))
    d["controls"] := Map("upgrade", Map("setting", "upgrade-key"))
    d["workflows"]["main"]["steps"] := [Map("id", "camera", "action", "camera", "zoomIn", 2, "zoomOut", 3, "tilt", 299), Map("id", "play", "action", "placements", "route", "test-map", "fallback", "shared")]
    MacroPackages.Save(first["package"], d, 1)
    plan := PlacementStore.Load(first["package"])["profile"]
    Assert(plan["routes"].Length == 2, "creator maps merged into player editor")
    start := PlacementStore.Step(), start["x"] := 350, start["y"] := 100
    place := PlacementStore.Step(), place["id"] := "place-one", place["kind"] := "place", place["x"] := 123, place["y"] := 234
    upgrade := PlacementStore.Step(), upgrade["id"] := "upgrade-one", upgrade["kind"] := "upgrade", upgrade["x"] := 123, upgrade["y"] := 234, upgrade["repeat"] := 2
    plan["routes"][1]["teams"][1]["steps"] := [start, place, upgrade]
    PlacementStore.Save(first["package"], plan)
    second := MacroPackages.New(), other := second["definition"], other["game"] := "shared-test-game"
    MacroPackages.Save(second["package"], other, 1)
    Assert(PlacementStore.Load(second["package"])["profile"]["routes"][1]["teams"][1]["steps"].Length == 3, "macros for same game share player placements")
    env := PlayFixture(), runner := FlowRunner(d, env)
    runner.PlacementData := plan
    runner.PlayKeys := PlayControls.Resolve(d, FlowSettings.Values(d, Map()), PlayControls.Defaults())
    runner.Run("main")
    Assert(env.Scrolls.Length == 5 && env.Scrolls[1] == "Up" && env.Scrolls[5] == "Down", "camera zooms in then out")
    Assert(env.Clicks.Length == 3 && env.Clicks[1][1] == 350 && env.Clicks[2][1] == 123, "shared fallback plays start, place and upgrade in order")
    Assert(env.Pressed["1"] == 1 && env.Pressed["T"] == 2 && env.Pressed["Q"] == 1 && env.Held.Count == 0, "settings override upgrade key; unit/cancel defaults and release apply")
    d["workflows"]["main"]["steps"] := [Map("id", "play", "action", "placements", "route", "test-map", "fallback", "error")]
    runner := FlowRunner(d, PlayFixture()), runner.PlacementData := plan, failed := false
    try runner.Run("main")
    catch Error
        failed := true
    Assert(failed, "unconfigured map without fallback fails explicitly")
    namedStart := JSON.parse(JSON.stringify(start)), namedStart["x"] := 450
    plan["routes"][2]["teams"][1]["steps"] := [namedStart, place, upgrade]
    d["settings"]["stage"] := Map("label", "Stage", "type", "select", "default", "test", "options", [Map("value", "test", "label", "Test map", "map", "test-map", "target", "")])
    d["workflows"]["main"]["steps"] := [Map("id", "play", "action", "placements", "route", "setting", "setting", "stage", "fallback", "error")]
    env := PlayFixture(), runner := FlowRunner(d, env), runner.PlacementData := plan
    runner.Run("main")
    Assert(env.Clicks[1][1] == 450, "selected dropdown chooses its mapped placement route")
    plan["useShared"] := 1
    env := PlayFixture(), runner := FlowRunner(d, env), runner.PlacementData := plan
    runner.Run("main")
    Assert(env.Clicks[1][1] == 350, "player shared override takes precedence over map selection")
    bad := JSON.parse(JSON.stringify(d)), bad["controls"]["upgrade"] := "{Run}"
    failed := false
    try FlowSchema.Validate(bad)
    catch Error
        failed := true
    Assert(failed, "control overrides reject input syntax injection")
    env := PlayFixture(), env.FailOnMove := 3
    d["workflows"]["main"]["steps"] := [Map("id", "camera", "action", "camera", "zoomIn", 1, "zoomOut", 1, "tilt", 299)]
    runner := FlowRunner(d, env), failed := false
    try runner.Run("main")
    catch Error
        failed := true
    Assert(failed && env.Held.Count == 0, "camera failure releases right mouse button")
    FileAppend("PASS: creator map metadata, shared per-game placements, camera sequence and cleanup, start/place/upgrade playback, configurable keys, fallback and schema guards.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (" err.File ":" err.Line ")`n", "**")
    ExitApp(1)
}
ExitApp(0)
Assert(value, message) {
    if !value
        throw Error(message)
}
class PlayFixture {
    __New() {
        this.Scrolls := [], this.Clicks := [], this.Pressed := Map(), this.Held := Map(), this.Moves := 0, this.FailOnMove := 0
    }
    Check() {
    }
    Move(x, y) {
        this.Moves++
        if this.FailOnMove && this.Moves >= this.FailOnMove
            throw Error("Fixture focus lost.")
    }
    Scroll(direction, ticks) => this.Scrolls.Push(direction)
    Click(x, y) => this.Clicks.Push([x, y])
    Key(key, down) {
        if down {
            this.Pressed[key] := this.Pressed.Get(key, 0)+1
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
