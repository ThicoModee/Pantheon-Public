#Requires AutoHotkey v2.0
#Include ..\Lib\framework\Runner.ahk

try {
    d := JSON.parse(FileRead(A_ScriptDir "\data\flow-fixture.json", "UTF-8"))
    d["settings"] := Map("stage", Map("type", "select", "label", "Stage", "default", "a", "options", [Map("value", "a", "label", "A", "target", "close-a"), Map("value", "b", "label", "B", "target", "close-b")]))
    d["workflows"] := Map("main", Map("name", "Main", "steps", []), "other", Map("name", "Other", "steps", [Map("id", "move", "action", "move", "x", 42, "y", 24)])), d["entry"] := "main"
    d["workflows"]["main"]["steps"] := [Map("id", "open", "action", "click-wait", "target", "enter-confirm", "ready", "close-a", "button", "Left", "timeoutMs", 100, "intervalMs", 100, "attempts", 3)]
    env := ComponentEnvironment(), r := FlowRunner(d, env), r.Run("main")
    Assert(env.Clicks == 2, "click-and-wait retries until a ready image confirms the screen")
    env := ComponentEnvironment(), env.Ready := true, FlowRunner(d, env).Run("main")
    Assert(env.Clicks == 0, "already-ready screen avoids toggling a menu closed")
    d["workflows"]["main"]["steps"] := [Map("id", "scroll", "action", "scroll-option", "setting", "stage", "x", 400, "y", 300, "direction", "Down", "maxScrolls", 4, "timeoutMs", 1000, "intervalMs", 100)]
    env := ComponentEnvironment(), env.ScrollMode := true, FlowRunner(d, env).Run("main")
    Assert(env.Scrolls == 2 && env.Clicks == 1, "selected-option component finds then clicks without another scroll")
    d["workflows"]["main"]["steps"][1]["maxScrolls"] := 1
    env := ComponentEnvironment(), env.ScrollMode := true, bounded := false
    try FlowRunner(d, env).Run("main")
    catch FlowImageError
        bounded := true
    Assert(bounded && env.Scrolls == 1 && env.Clicks == 0, "scroll limit stops without clicking an undetected option")
    d["workflows"]["main"]["steps"] := [Map("id", "dismiss", "action", "dismiss", "target", "enter-confirm", "ready", "close-a", "button", "Left", "timeoutMs", 1000, "intervalMs", 100)]
    env := ComponentEnvironment(), FlowRunner(d, env).Run("main")
    Assert(env.Clicks == 2, "reward component stops clicking when its destination appears")
    d["workflows"]["main"]["steps"] := [Map("id", "choice", "action", "setting-call", "setting", "stage", "routes", Map("a", "other", "b", "other"))]
    env := ComponentEnvironment(), FlowRunner(d, env).Run("main")
    Assert(env.LastX == 42, "setting choice runs its mapped sequence")
    d["workflows"]["main"]["steps"][1]["routes"]["b"] := "main", rejected := false
    try FlowSchema.Validate(d)
    catch Error
        rejected := true
    Assert(rejected, "setting routes cannot bypass recursive-call validation")
    FileAppend("PASS: click-and-wait retries, ready-screen protection, selected-option scrolling, reward dismissal and settings-to-sequence routing.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (" err.File ":" err.Line ")`n", "**")
    ExitApp(1)
}
ExitApp(0)
Assert(value, message) {
    if !value
        throw Error(message)
}
class ComponentEnvironment {
    __New() {
        this.Clicks := 0, this.Scrolls := 0, this.ScrollMode := false, this.Ready := false, this.LastX := 0
    }
    Check() {
    }
    Find(target) {
        if target["kind"] == "point"
            return Map("x", target["x"], "y", target["y"])
        if target["name"] == "Close button A" && (this.Ready || (this.ScrollMode ? this.Scrolls >= 2 : this.Clicks >= 2))
            return Map("x", 100, "y", 100)
        return 0
    }
    Click(x, y, button := "Left") => this.Clicks++
    Move(x, y) => this.LastX := x
    Scroll(direction, ticks) => this.Scrolls++
    Sleep(ms) => Sleep(1)
    Trace(*) {
    }
    Release() {
    }
}
