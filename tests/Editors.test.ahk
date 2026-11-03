#Requires AutoHotkey v2.0
#Include ..\Lib\HubModel.ahk
#Include ..\Lib\Desktop.ahk

try {
    MacroPackages.Root := A_ScriptDir "\..\test-results\editors-" A_TickCount
    MacroPackages.Bundled := MacroPackages.Root "\supplied"
    PlacementStore.Root := MacroPackages.Root "\placements"
    MacroPackages.Cached := 0, MacroHub.Config["developer"] := 1
    created := MacroPackages.New(), id := created["package"], d := created["definition"]
    d["maps"] := Map("story", Map("name", "Story map"), "story-act-1", Map("name", "Act 1", "parent", "story"), "story-infinite", Map("name", "Infinite", "parent", "story"))
    d["settings"] := Map("upgrade-key", Map("label", "Upgrade key", "type", "key", "default", "T", "control", "upgrade"))
    d["workflows"]["main"]["steps"] := [Map("id", "first", "name", "Open menu", "action", "delay", "durationMs", 0)]
    MacroPackages.Save(id, d, 1)
    Assert(MacroPackages.Load(id)["definition"]["workflows"]["main"]["steps"][1]["name"] == "Open menu", "step names survive persistence")
    MacroPackages.SaveValues(id, Map("upgrade-key", "F8"))
    resolved := PlayControls.Resolve(d, MacroPackages.Values(id), PlayControls.Defaults())
    Assert(resolved["upgrade"] == "F8" && resolved["slot-1"] == "1", "single-key override changes only selected action")
    plan := PlacementStore.Load(id)["profile"]
    Assert(plan["routes"].Length == 4, "root map and children create independent routes")
    placed := PlacementStore.Step(), placed["id"] := "place", placed["kind"] := "place", placed["x"] := 100, placed["y"] := 200
    plan["routes"][3]["teams"][1]["steps"].Push(placed)
    PlacementStore.Save(id, plan)
    loaded := PlacementStore.Load(id)["profile"]
    Assert(loaded["routes"][3]["teams"][1]["steps"].Length == 2 && loaded["routes"][4]["teams"][1]["steps"].Length == 1, "acts share image but keep independent timelines")
    token := Gdip_Startup(), bitmap := Gdip_CreateBitmap(800, 600)
    try {
        PlacementStore.WriteFrame(id, "story-act-1", bitmap)
        Assert(FileExist(PlacementStore.Folder(id) "\story.png") && !FileExist(PlacementStore.Folder(id) "\story-act-1.png"), "child import stores screenshot on parent")
        frames := PlacementStore.Load(id)["frames"]
        Assert(frames["story"] && frames["story-act-1"] && frames["story-infinite"], "all map children see the same screenshot")
        Assert(PlacementStore.Frame(id, "story")["image"] == PlacementStore.Frame(id, "story-infinite")["image"], "child reads exactly the parent image")
    } finally {
        Gdip_DisposeImage(bitmap), Gdip_Shutdown(token)
    }
    bad := Clone(d), bad["settings"]["upgrade-key"]["default"] := "Ctrl+R"
    Reject(bad, "key combinations rejected")
    bad := Clone(d), bad["settings"]["upgrade-key"]["default"] := "{Run}"
    Reject(bad, "key syntax injection rejected")
    bad := Clone(d), bad["settings"]["second"] := Clone(d["settings"]["upgrade-key"])
    Reject(bad, "duplicate action overrides rejected")
    bad := Clone(d), bad["maps"]["story-act-1"]["parent"] := "missing"
    Reject(bad, "orphan child rejected")
    bad := Clone(d), bad["maps"]["story"]["parent"] := "story-act-1"
    Reject(bad, "cyclic map group rejected")
    bad := Clone(d), bad["workflows"]["main"]["steps"][1]["name"] := []
    Reject(bad, "step names stay plain text")
    legacy := Clone(d)
    legacy["settings"]["upgrade-key"] := Map("label", "Upgrade", "type", "select", "default", "key-r", "options", [Map("value", "key-r", "label", "R", "target", ""), Map("value", "key-t", "label", "T", "target", "")])
    legacy["controls"] := Map("upgrade", Map("setting", "upgrade-key"))
    PlayControls.Upgrade(legacy), FlowSchema.Validate(legacy)
    Assert(legacy["settings"]["upgrade-key"]["type"] == "key" && legacy["settings"]["upgrade-key"]["default"] == "R", "legacy dropdown overrides migrate to single-key settings")
    values := FlowSettings.Values(legacy, Map("upgrade-key", "key-t"))
    Assert(values["upgrade-key"] == "T", "old saved key selections retain their value")
    FileAppend("PASS: named steps, single-key settings and compatibility, action isolation, map hierarchy, shared screenshots with separate act timelines, invalid key/name/parent rejection.`n", "*")
} catch Error as err {
    FileAppend("FAIL: " err.Message " (" err.File ":" err.Line ")`n", "**")
    ExitApp(1)
}
ExitApp(0)
Clone(value) => JSON.parse(JSON.stringify(value))
Assert(value, message) {
    if !value
        throw Error(message)
}
Reject(value, message) {
    rejected := false
    try FlowSchema.Validate(value)
    catch Error
        rejected := true
    Assert(rejected, message)
}
