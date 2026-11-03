#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\Settings.ahk
#Include %A_LineFile%\..\framework\Runner.ahk
#Include %A_LineFile%\..\framework\RobloxEnvironment.ahk

class PantheonBridge {
    static Parent := 0
    static Token := ""
    static Folder := ""
    static Game := 0
    static Running := false
    static FlowDefinition := 0
    static ActiveFlow := 0
    static Embedded() => A_Args.Length >= 5 && A_Args[1] == "--pantheon-hub"
    static HasWorkflow(id) {
        if !this.Embedded() || !FileExist(this.Folder "\framework.json")
            return false
        if !this.FlowDefinition {
            if FileGetSize(this.Folder "\framework.json") > 500000
                throw Error("Framework snapshot exceeds 500 KB.")
            this.FlowDefinition := FlowSchema.Validate(JSON.parse(FileRead(this.Folder "\framework.json", "UTF-8")))
        }
        return this.FlowDefinition["workflows"].Has(id)
    }
    static Workflow(id) {
        if !this.HasWorkflow(id)
            throw Error("Workflow is not available: " id)
        environment := RobloxFlowEnvironment(this.Game, ObjBindMethod(this, "Log"), ObjBindMethod(this, "Result"))
        values := Map()
        if FileExist(this.Folder "\settings-values.json") {
            if FileGetSize(this.Folder "\settings-values.json") > 500000
                throw Error("Macro settings snapshot exceeds 500 KB.")
            values := JSON.parse(FileRead(this.Folder "\settings-values.json", "UTF-8"))
        }
        this.ActiveFlow := FlowRunner(this.FlowDefinition, environment, values)
        if FileExist(this.Folder "\placements.json") {
            if FileGetSize(this.Folder "\placements.json") > 2000000
                throw Error("Placement snapshot exceeds 2 MB.")
            this.ActiveFlow.PlacementData := PlacementPlan.Validate(JSON.parse(FileRead(this.Folder "\placements.json", "UTF-8")))
        }
        if FileExist(this.Folder "\play-controls.json")
            this.ActiveFlow.PlayKeys := PlayControls.Validate(JSON.parse(FileRead(this.Folder "\play-controls.json", "UTF-8")))
        try this.ActiveFlow.Run(id)
        finally this.ActiveFlow := 0
    }
    static Initialize(guiObj) {
        if !this.Embedded()
            return
        this.Parent := Integer(A_Args[2]), this.Token := A_Args[3], this.Folder := A_Args[4], this.Game := Integer(A_Args[5])
        if !RegExMatch(this.Token, "^[0-9a-f]{32}$") || !WinExist("ahk_id " this.Parent)
            ExitApp(1)
        guiObj.Hide()
        OnMessage(0x4A, ObjBindMethod(this, "Receive"))
        OnError(ObjBindMethod(this, "Error"))
        OnExit(ObjBindMethod(this, "Cleanup"))
        SetTimer(ObjBindMethod(this, "CheckParent"), 1000)
        this.State("ready")
    }
    static State(value) => IniWrite(value, this.Folder "\state.ini", "Engine", "State")
    static Receive(sender, packet, *) {
        if sender != this.Parent || NumGet(packet, 0, "ptr") != 0x50414E54
            return 0
        bytes := NumGet(packet, A_PtrSize, "uint")
        if bytes < 2 || bytes > 512
            return 0
        parts := StrSplit(StrGet(NumGet(packet, 2 * A_PtrSize, "ptr"), bytes // 2 - 1, "UTF-16"), "|")
        if parts.Length != 2 || parts[1] != this.Token
            return 0
        switch parts[2] {
            case "start":
                if this.Running || IniRead(this.Folder "\state.ini", "Engine", "State", "") != "ready"
                    return 0
                this.State("starting")
                SetTimer(ObjBindMethod(this, "Start"), -1)
            case "pause": this.TogglePause()
            case "exit": SetTimer((*) => ExitApp(), -1)
            default: return 0
        }
        return 1
    }
    static Start() {
        this.Running := true
        this.State("running")
        failed := false
        try {
            InitializeMacro()
        } catch Error as err {
            if err is FlowStop
                this.Log(err.Message)
            else {
                failed := true
                this.Error(err)
            }
        } finally {
            this.Running := false
            if !failed
                this.State("ready")
        }
    }
    static TogglePause() {
        if A_IsPaused {
            if this.ActiveFlow {
                this.Setup()
                this.ActiveFlow.Environment.Resume()
            }
            this.State("running")
            Pause(false)
        } else {
            if this.ActiveFlow
                this.ActiveFlow.Environment.Suspend()
            this.State("paused")
            Pause(true)
        }
    }
    static Setup() {
        if !this.GetGame()
            throw Error("The mounted Roblox window is unavailable.")
        WinShow("ahk_id " this.Game)
        WinActivate("ahk_id " this.Game)
        return true
    }
    static GetGame() {
        if !this.Game || !DllCall("IsWindow", "ptr", this.Game)
            this.Game := WinExist("ahk_exe RobloxPlayerBeta.exe")
        return this.Game
    }
    static Result(won) {
        key := won ? "Wins" : "Losses", path := this.Folder "\state.ini"
        IniWrite(Integer(IniRead(path, "Stats", key, 0))+1, path, "Stats", key)
        this.Log(won ? "Victory detected." : "Defeat detected.")
    }
    static Log(text) {
        if this.Embedded() && this.Folder != ""
            try FileAppend(FormatTime(, "HH:mm:ss") "  " text "`n", this.Folder "\log.txt", "UTF-8-RAW")
    }
    static Error(err, *) {
        this.Log("Error: " err.Message " (" err.File ":" err.Line ")")
        if this.Folder != ""
            this.State("error")
        return true
    }
    static CheckParent() {
        if !DllCall("IsWindow", "ptr", this.Parent)
            ExitApp()
    }
    static Cleanup(*) {
        if this.ActiveFlow
            this.ActiveFlow.Environment.Release()
        if this.Running && this.Game && DllCall("IsWindow", "ptr", this.Game)
            try ControlSend("{w up}{a up}{s up}{d up}{Space up}{LButton up}{RButton up}", , "ahk_id " this.Game)
    }
}
