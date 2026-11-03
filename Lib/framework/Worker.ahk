#Requires AutoHotkey v2.0
#SingleInstance Off
#Include %A_LineFile%\..\..\EngineBridge.ahk

if !PantheonBridge.Embedded()
    ExitApp(1)
workerWindow := Gui()
PantheonBridge.Initialize(workerWindow)
Persistent()

InitializeMacro() {
    if !PantheonBridge.HasWorkflow("main") && !PantheonBridge.FlowDefinition
        throw Error("No validated macro configuration is available.")
    definition := PantheonBridge.FlowDefinition
    PantheonBridge.Log("Running data macro: " definition["name"])
    loop {
        PantheonBridge.Workflow(definition["entry"])
        if definition.Get("runMode", "once") != "repeat"
            break
        Sleep(250)
    }
    PantheonBridge.Log("Main sequence completed.")
}
