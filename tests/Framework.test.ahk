#Requires AutoHotkey v2.0

#Include ..\Lib\HubModel.ahk

#Include ..\Lib\Desktop.ahk

#Include ..\Lib\framework\Runner.ahk

#Include ..\Lib\framework\RobloxEnvironment.ahk



try {

    definition := JSON.parse(FileRead(A_ScriptDir "\data\flow-fixture.json", "UTF-8"))

    example := JSON.parse(JSON.stringify(definition))

    example["workflows"]["example"] := Map("name", "Enter stage example", "steps", [

        Map("id", "retry-entry", "action", "retry", "steps", [

            Map("id", "click-one", "action", "click-point", "x", 10, "y", 20, "button", "Left"),

            Map("id", "click-two", "action", "click-point", "x", 30, "y", 40, "button", "Right"),

            Map("id", "walk", "action", "walk", "keys", ["W", "D"], "sprint", 1, "sprintKey", "Shift", "durationMs", 30)],

            "condition", ImageCondition("popup-close"), "attempts", 3, "timeoutMs", 100, "intervalMs", 100, "failure", "error"),

        Map("id", "move", "action", "move", "x", 600, "y", 300),

        Map("id", "scroll", "action", "scroll", "direction", "Down", "ticks", 2, "count", 3, "intervalMs", 0),

        Map("id", "select", "action", "click-point", "x", 100, "y", 200, "button", "Left"),

        Map("id", "start", "action", "click-point", "x", 400, "y", 500, "button", "Left"),

        Map("id", "loaded", "action", "wait", "condition", ImageCondition("close-a"), "timeoutMs", 100, "missing", "error")])

    example["workflows"]["example"]["steps"][6]["timeoutMs"] := 3600000

    environment := FixtureEnvironment(), environment.FoundAfter := Map("Popup close", 4, "Close button A", 6)

    runner := FlowRunner(example, environment), runner.Run("example")

    Assert(environment.Clicks.Length == 6, "entry sequence retries only until chamber detection succeeds")

    Assert(environment.Clicks[2][3] == "Right", "right clicks retain their mouse button")

    Assert(environment.MaxHeld == 3 && environment.Held.Count == 0, "diagonal sprint holds W/D/Shift together and releases them")

    Assert(environment.Moves[1][1] == 600 && environment.Scrolls.Length == 3, "mouse movement and repeated scrolling execute in sequence")

    result := Map("id", "result", "action", "outcome", "victory", "popup-close", "defeat", "close-a", "timeoutMs", 100,
        "thenSteps", [Map("id", "win", "action", "move", "x", 10, "y", 20)],
        "elseSteps", [Map("id", "lose", "action", "move", "x", 30, "y", 40)])
    example["workflows"]["result"] := Map("name", "Match result", "steps", [result])
    environment := FixtureEnvironment(), environment.FoundAfter := Map("Popup close", 0)
    FlowRunner(example, environment).Run("result")
    Assert(environment.Moves[1][1] == 10 && environment.Results.Length == 1 && environment.Results[1], "match result counts one victory before dispatch")
    environment := FixtureEnvironment(), environment.FoundAfter := Map("Close button A", 0)
    FlowRunner(example, environment).Run("result")
    Assert(environment.Moves[1][1] == 30 && environment.Results.Length == 1 && !environment.Results[1], "match result counts one defeat before dispatch")
    environment := FixtureEnvironment(), timedOut := false
    try FlowRunner(example, environment).Run("result")
    catch FlowImageError
        timedOut := true
    Assert(timedOut && environment.Results.Length == 0, "match result timeout does not count a match")

    combo := Map("operator", "all", "checks", [Map("target", "popup-close", "state", "present"), Map("operator", "any", "checks", [Map("target", "close-a", "state", "present"), Map("target", "close-b", "state", "absent")])])

    example["workflows"]["logic"] := Map("name", "Logic", "steps", [Map("id", "branch", "action", "if", "condition", combo,

        "thenSteps", [Map("id", "yes", "action", "click-point", "x", 25, "y", 35, "button", "Right")], "elseSteps", [])])

    environment := FixtureEnvironment(), environment.FoundAfter := Map("Popup close", 0)

    runner := FlowRunner(example, environment), runner.Run("logic")

    Assert(environment.Clicks.Length == 1 && environment.Clicks[1][1] == 25, "AND / OR / not-detected conditions select the correct inline branch")

    example["workflows"]["finish"] := Map("name", "Finish loop", "steps", [Map("id", "finish", "action", "until", "condition", ImageCondition("popup-close"), "timeoutMs", 1000, "intervalMs", 100, "failure", "error",

        "steps", [Map("id", "poll-action", "action", "scroll", "direction", "Up", "ticks", 1, "count", 1, "intervalMs", 0)])])

    environment := FixtureEnvironment(), environment.DetectAfterScroll := true

    runner := FlowRunner(example, environment), runner.Run("finish")

    Assert(environment.Scrolls.Length == 2, "finish detection loop stops after the image is found")

    example["workflows"]["short-loop"] := Map("name", "Short loop", "steps", [Map("id", "deadline", "action", "until", "condition", ImageCondition("popup-close"), "timeoutMs", 100, "intervalMs", 100, "failure", "continue",

        "steps", [Map("id", "walk", "action", "walk", "keys", ["W", "D"], "sprint", 1, "sprintKey", "Shift", "durationMs", 1000)]),

        Map("id", "continued", "action", "move", "x", 1, "y", 2)])

    environment := FixtureEnvironment(), environment.RealTime := true

    runner := FlowRunner(example, environment), started := A_TickCount, runner.Run("short-loop")

    Assert(A_TickCount-started < 500 && environment.Held.Count == 0 && environment.Moves.Length == 1, "loop timeout interrupts walking, releases all keys and can continue")

    example["workflows"]["retry-failure"] := Map("name", "Retry failure", "steps", [Map("id", "retry", "action", "retry", "steps", [Map("id", "check", "action", "wait", "condition", ImageCondition("popup-close"), "timeoutMs", 100, "missing", "error")],

        "condition", ImageCondition("popup-close"), "attempts", 2, "timeoutMs", 100, "intervalMs", 100, "failure", "continue"), Map("id", "continued", "action", "move", "x", 2, "y", 3)])

    environment := FixtureEnvironment(), runner := FlowRunner(example, environment), runner.Run("retry-failure")

    Assert(environment.Moves.Length == 1 && environment.Waits >= 2, "retry handles failed image checks and continues after its attempt limit when configured")

    configured := JSON.parse(JSON.stringify(definition))

    configured["settings"] := Map(

        "stage", Map("label", "Stage", "type", "select", "default", "stage-one", "options", [Map("value", "stage-one", "label", "Stage 1", "target", "enter-confirm"), Map("value", "stage-two", "label", "Stage 2", "target", "enter-start")]),

        "farm-portals", Map("label", "Farm portals", "type", "toggle", "default", 0),

        "shop", Map("label", "Shop priorities", "type", "priority", "default", ["first", "second"], "options", [Map("value", "first", "label", "First item", "target", "enter-confirm"), Map("value", "second", "label", "Second item", "target", "enter-start")]),

        "walk-time", Map("label", "Walk time", "type", "number", "default", 30, "min", 30, "max", 1000))

    configured["workflows"]["settings-test"] := Map("name", "Settings test", "steps", [

        Map("id", "stage", "action", "click-setting", "setting", "stage", "button", "Left", "timeoutMs", 0, "missing", "error"),

        Map("id", "portal-flag", "action", "if", "condition", Map("operator", "all", "checks", [Map("setting", "farm-portals", "comparison", "equals", "value", 1)]),

            "thenSteps", [Map("id", "enabled", "action", "click-point", "x", 99, "y", 99, "button", "Left")], "elseSteps", []),

        Map("id", "shop-order", "action", "for-setting", "setting", "shop", "steps", [Map("id", "buy", "action", "click-setting", "setting", "shop", "button", "Left", "timeoutMs", 0, "missing", "error")]),

        Map("id", "press", "action", "press", "key", "Space", "count", 2, "intervalMs", 0),

        Map("id", "bound-time", "action", "walk", "keys", ["W"], "sprint", 0, "sprintKey", "Shift", "durationMs", Map("setting", "walk-time"))])

    environment := FixtureEnvironment()

    selected := Map("stage", "stage-two", "farm-portals", 1, "shop", ["second", "first"], "walk-time", 30)

    runner := FlowRunner(configured, environment, selected), runner.Run("settings-test")

    Assert(environment.Clicks.Length == 4 && environment.Clicks[1][2] == 460 && environment.Clicks[2][1] == 99, "selected stage and portal flag drive actions")

    Assert(environment.Clicks[3][2] == 460 && environment.Clicks[4][2] == 430, "priority list order controls shop option clicks")

    Assert(environment.KeyDowns["Space"] == 2 && environment.Held.Count == 0, "press-key action taps rather than leaving keys held")

    environment := FixtureEnvironment(), runner := FlowRunner(configured, environment), runner.Run("settings-test")

    Assert(environment.Clicks.Length == 3 && environment.Clicks[1][2] == 430, "disabled flags and default stage selections take the other path")

    configured["workflows"]["stop-test"] := Map("name", "Stop", "steps", [Map("id", "stop", "action", "stop"), Map("id", "never", "action", "click-point", "x", 1, "y", 2, "button", "Left")])

    environment := FixtureEnvironment(), runner := FlowRunner(configured, environment), stopped := false

    try runner.Run("stop-test")

    catch FlowStop

        stopped := true

    Assert(stopped && environment.Clicks.Length == 0 && environment.Released, "stop action ends the macro without following input")

    imageDefinition := JSON.parse(JSON.stringify(configured))

    for targetId in ["enter-confirm", "enter-start"] {

        imageDefinition["targets"][targetId]["kind"] := "pattern"

        imageDefinition["targets"][targetId]["pattern"] := "|<>*99$1.k"

    }

    selectedCondition := Map("operator", "all", "checks", [Map("selectedImage", "stage", "state", "present")])

    FlowSchema.Condition(imageDefinition, selectedCondition)

    environment := FixtureEnvironment(), environment.FoundAfter := Map("Second point", 0)

    runner := FlowRunner(imageDefinition, environment, selected)

    runner.Budget := 100, runner.Started := A_TickCount
    Assert(runner.Condition(selectedCondition), "image check follows selected dropdown option")

    runner := FlowRunner(imageDefinition, environment)

    runner.Budget := 100, runner.Started := A_TickCount
    Assert(!runner.Condition(selectedCondition), "unselected option image cannot satisfy the check")

    badSetting := JSON.parse(JSON.stringify(configured)), badSetting["settings"]["walk-time"]["max"] := 1000000

    Reject(badSetting, "numeric setting bounds cannot escape action limits")

    bad := JSON.parse(JSON.stringify(definition)), bad["workflows"]["enter-map"]["steps"][1]["target"] := "missing"

    Reject(bad, "dangling target rejected")

    bad := JSON.parse(JSON.stringify(definition)), bad["workflows"]["enter-map"]["steps"].Push(Map("id", "recursive", "action", "call", "workflow", "enter-map"))

    Reject(bad, "recursive workflows rejected")

    bad := JSON.parse(JSON.stringify(definition)), bad["workflows"]["enter-map"]["steps"][1] := Map("id", "command", "action", "run", "path", "cmd.exe")

    Reject(bad, "executable actions rejected")

    bad := JSON.parse(JSON.stringify(definition)), bad["targets"]["enter-confirm"]["x"] := 800

    Reject(bad, "out of client coordinates rejected")

    bad := JSON.parse(JSON.stringify(definition)), bad["workflows"]["enter-map"]["steps"][1] := Map("id", "injection", "action", "key", "key", "{Run}", "durationMs", 30)

    Reject(bad, "input syntax injection rejected")

    bad := JSON.parse(JSON.stringify(example)), bad["workflows"]["example"]["steps"][1]["steps"][3]["keys"] := ["W", "S"]

    Reject(bad, "opposing movement directions rejected")

    bad := JSON.parse(JSON.stringify(example)), bad["workflows"]["example"]["steps"][1]["steps"][2]["button"] := "Middle"

    Reject(bad, "unsupported mouse buttons rejected")

    d := JSON.parse(JSON.stringify(definition))

    d["workflows"]["hold"] := Map("name", "Hold", "steps", [Map("id", "key", "action", "key", "key", "W", "durationMs", 200)])

    environment := FixtureEnvironment(), environment.FailAfter := 3

    runner := FlowRunner(d, environment), failed := false

    try runner.Run("hold")

    catch Error

        failed := true

    Assert(failed && environment.Held.Count == 0 && environment.Released, "focus failure releases held input")

    environment := FixtureEnvironment(), runner := FlowRunner(d, environment), environment.Runner := runner

    environment.CancelAfter := 3, failed := false

    try runner.Run("hold")

    catch Error

        failed := true

    Assert(failed && environment.Held.Count == 0, "cancellation releases held input")

    pausedEnvironment := PauseFixtureEnvironment()

    pausedEnvironment.Key("W", true), pausedEnvironment.Suspend()

    Assert(pausedEnvironment.Held.Count == 0, "pausing releases held keys")

    pausedEnvironment.Resume()

    Assert(pausedEnvironment.Held.Has("W"), "resume restores a bounded key hold")

    pausedEnvironment.Suspend(), pausedEnvironment.Fail := true, failed := false

    try pausedEnvironment.Resume()

    catch Error

        failed := true

    Assert(failed && pausedEnvironment.Held.Count == 0, "resume cannot restore input without the expected focus")

    d["workflows"]["missing"] := Map("name", "Missing", "steps", [Map("id", "wait", "action", "wait", "target", "popup-close", "timeoutMs", 100, "missing", "error")])

    environment := FixtureEnvironment(), runner := FlowRunner(d, environment), failed := false

    try runner.Run("missing")

    catch Error as err

        failed := InStr(err.Message, "popup-close") && InStr(err.Message, "missing / wait")

    Assert(failed, "missing targets report workflow and step")

    d["workflows"]["budget-leaf"] := Map("name", "Budget leaf", "steps", [Map("id", "empty", "action", "delay", "durationMs", 0)])

    previous := "budget-leaf"

    loop 4 {

        id := "budget-" A_Index

        d["workflows"][id] := Map("name", id, "steps", [Map("id", "repeat", "action", "repeat", "workflow", previous, "count", 20)])

        previous := id

    }

    runner := FlowRunner(d, FixtureEnvironment()), failed := false

    try runner.Run(previous)

    catch Error as err

        failed := InStr(err.Message, "execution limit")

    Assert(failed, "nested repeats respect the global execution budget")

    FileAppend("PASS: settings-driven stages, flags, priorities and numeric parameters; press/stop actions; entry retries, movement, image logic and deadlines; strict schema, cleanup, revisions and developer gate.`n", "*")

} catch Error as err {

    FileAppend("FAIL: " err.Message " (" err.File ":" err.Line ")`n", "**")

    ExitApp(1)

}

ExitApp(0)

Reject(raw, message) {

    rejected := false

    try FlowSchema.Validate(raw)

    catch Error

        rejected := true

    Assert(rejected, message)

}

Assert(value, message) {

    if !value

        throw Error(message)

}

ImageCondition(target) => Map("operator", "all", "checks", [Map("target", target, "state", "present")])

class FixtureEnvironment {
    Results := []

    __New() {

        this.Clicks := [], this.Held := Map(), this.Visible := false, this.Checks := 0

        this.FailAfter := 0, this.CancelAfter := 0, this.Runner := 0, this.Released := false

        this.Moves := [], this.Scrolls := [], this.FoundAfter := Map(), this.MaxHeld := 0, this.DetectAfterScroll := false, this.RealTime := false, this.Waits := 0, this.KeyDowns := Map()

    }

    Check() {

        this.Checks++

        if this.FailAfter && this.Checks >= this.FailAfter

            throw Error("Focus lost.")

        if this.CancelAfter && this.Checks >= this.CancelAfter

            this.Runner.Cancel()

    }

    Find(target) {

        visible := this.Visible || (this.FoundAfter.Has(target["name"]) && this.Clicks.Length >= this.FoundAfter[target["name"]]) || (this.DetectAfterScroll && this.Scrolls.Length >= 2)

        return target["kind"] == "point" ? Map("x", target["x"], "y", target["y"]) : visible ? Map("x", 100, "y", 100) : 0

    }

    Click(x, y, button := "Left") => this.Clicks.Push([x, y, button])

    Move(x, y) => this.Moves.Push([x, y])

    Scroll(direction, ticks) => this.Scrolls.Push([direction, ticks])

    Key(key, down) {

        if down {

            this.Held[key] := true

            this.KeyDowns[key] := this.KeyDowns.Get(key, 0)+1

        } else if this.Held.Has(key)

            this.Held.Delete(key)

        this.MaxHeld := Max(this.MaxHeld, this.Held.Count)

    }

    Sleep(ms) {

        this.Waits++

        Sleep(this.RealTime ? ms : Min(ms, 5))

    }

    Result(won) => this.Results.Push(won)

    Trace(*) {

    }

    Release() => (this.Held := Map(), this.Released := true)

}

class PauseFixtureEnvironment extends RobloxFlowEnvironment {

    __New() {

        super.__New(0, (*) => 0)

        this.Fail := false

    }

    Check() {

        if this.Fail

            throw Error("Focus lost.")

    }

    Key(key, down) {

        if down {

            this.Check()

            this.Held[key] := true

        } else if this.Held.Has(key)

            this.Held.Delete(key)

    }

    Release() => this.Held := Map()

}
