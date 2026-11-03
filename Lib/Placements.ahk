#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\Settings.ahk
#Include %A_LineFile%\..\framework\PlacementPlan.ahk
#Include %A_LineFile%\..\Developer.ahk
#Include %A_LineFile%\..\framework\Runner.ahk
#Include %A_LineFile%\..\framework\RobloxEnvironment.ahk

class PlacementStore extends PlacementPlan {
    static Root := A_ScriptDir "\data\placements"
    static Slug(name) => Trim(RegExReplace(StrLower(name), "[^a-z0-9]+", "-"), "-")
    static Step() => Map("id", "start-game", "kind", "start", "slot", 1, "x", 0, "y", 0, "delayMs", 0, "repeat", 1, "timeoutMs", 30000)
    static Route(id, name) {
        teams := []
        loop 8
            teams.Push(Map("steps", [this.Step()]))
        return Map("id", id, "name", name, "team", 1, "teams", teams)
    }
    static Defaults() {
        routes := [this.Route("shared", "Shared setup")]
        return Map("version", 1, "selectedRoute", "shared", "routes", routes)
    }
    static Folder(mode) => this.Root "\" MacroPackages.Load(MacroHub.Mode(mode))["definition"]["game"]
    static Load(mode) {
        path := this.Folder(mode) "\plan.json"
        if FileExist(path) && FileGetSize(path) > 2000000
            throw Error("Placement setup exceeds 2 MB.")
        p := FileExist(path) ? this.Validate(JSON.parse(FileRead(path, "UTF-8"))) : this.Defaults()
        for id, spec in MacroPackages.Load(mode)["definition"].Get("maps", Map()) {
            found := false
            for route in p["routes"]
                if route["id"] == id {
                    found := true
                    route["parent"] := spec.Get("parent", "")
                }
            if !found {
                route := this.Route(id, spec["name"])
                route["parent"] := spec.Get("parent", "")
                p["routes"].Push(route)
            }
        }
        frames := Map()
        for r in p["routes"]
            frames[r["id"]] := FileExist(this.Folder(mode) "\" (r.Get("parent", "") == "" ? r["id"] : r["parent"]) ".png") ? 1 : 0
        return Map("profile", p, "frames", frames, "playback", PlacementPlan.Config(MacroPackages.Load(mode)["definition"].Get("playback", Map())))
    }
    static Save(mode, raw) {
        if HubEngine.Busy()
            throw Error("Stop the macro before saving placement changes.")
        clean := this.Validate(raw, true, MacroPackages.Load(mode)["definition"].Get("playback", Map()))
        if StrPut(JSON.stringify(clean), "UTF-8") > 2000000
            throw Error("Placement setup exceeds 2 MB.")
        ProfileStore.WriteJson(this.Folder(mode) "\plan.json", clean)
        return Map("saved", 1)
    }
    static ImageId(mode, id) {
        this.RouteId(id)
        for route in this.Load(mode)["profile"]["routes"]
            if route["id"] == id
                return route.Get("parent", "") == "" ? id : route["parent"]
        return id
    }
    static Frame(mode, id) {
        path := this.Folder(mode) "\" this.ImageId(mode, id) ".png"
        if !FileExist(path)
            return Map("image", "")
        bytes := FileRead(path, "RAW")
        if bytes.Size > 5000000
            throw Error("Screenshot exceeds the supported size.")
        DllCall("crypt32\CryptBinaryToStringW", "ptr", bytes, "uint", bytes.Size, "uint", 0x40000001, "ptr", 0, "uint*", &chars := 0)
        result := Buffer(chars * 2)
        if !DllCall("crypt32\CryptBinaryToStringW", "ptr", bytes, "uint", bytes.Size, "uint", 0x40000001, "ptr", result, "uint*", &chars)
            throw Error("Could not read the screenshot.")
        return Map("image", "data:image/png;base64," StrGet(result, "UTF-16"))
    }
    static WriteFrame(mode, id, bitmap) {
        if Gdip_GetImageWidth(bitmap) != 800 || Gdip_GetImageHeight(bitmap) != 600
            throw Error("The spawn screenshot must be 800 x 600 pixels.")
        folder := this.Folder(mode)
        DirCreate(folder)
        path := folder "\" this.ImageId(mode, id) ".png"
        temp := path ".capture.png"
        if Gdip_SaveBitmapToFile(bitmap, temp) != 0
            throw Error("Could not save the screenshot.")
        FileMove(temp, path, 1)
        return this.Frame(mode, id)
    }
    static Capture(mode, id) {
        token := Gdip_Startup(), bitmap := 0
        try {
            bitmap := GameCapture.Bitmap()
            return this.WriteFrame(mode, id, bitmap)
        } finally {
            if bitmap
                Gdip_DisposeImage(bitmap)
            Gdip_Shutdown(token)
        }
    }
    static CameraStep(steps) {
        for step in steps {
            if step["action"] == "camera"
                return step
            for field in ["steps", "thenSteps", "elseSteps"]
                if step.Has(field) {
                    found := this.CameraStep(step[field])
                    if found
                        return found
                }
        }
        return 0
    }
    static Align(mode) {
        if HubEngine.Busy()
            throw Error("Stop the macro before aligning Roblox.")
        definition := MacroPackages.Load(MacroHub.Mode(mode))["definition"]
        camera := Map("id", "align-camera", "action", "camera", "zoomIn", 20, "zoomOut", 20, "tilt", 299)
        for flow in definition["workflows"]
            if found := this.CameraStep(definition["workflows"][flow]["steps"]) {
                camera := found
                break
            }
        token := Gdip_Startup(), bitmap := 0
        try {
            bitmap := GameCapture.Bitmap(0, 0, (hwnd) => this.AlignCamera(hwnd, definition, camera, mode))
            return Map("aligned", 1)
        } finally {
            if bitmap
                Gdip_DisposeImage(bitmap)
            Gdip_Shutdown(token)
        }
    }
    static AlignCamera(hwnd, definition, camera, mode) {
        environment := RobloxFlowEnvironment(hwnd, (text) => MacroHub.Log(text))
        runner := FlowRunner(definition, environment, MacroPackages.Values(mode))
        runner.Started := A_TickCount
        try runner.ExecuteSteps([camera], "Align Roblox")
        finally environment.Release()
    }
    static ImportFrame(mode, id) {
        if HubEngine.Busy()
            throw Error("Stop the macro before importing a screenshot.")
        file := FileSelect(3, , "Import spawn screenshot (800 x 600)", "Images (*.png; *.jpg; *.bmp)")
        if file == ""
            return Map("cancelled", 1)
        token := Gdip_Startup(), bitmap := 0
        try {
            bitmap := Gdip_CreateBitmapFromFile(file)
            if !bitmap
                throw Error("The image could not be opened.")
            return this.WriteFrame(mode, id, bitmap)
        } finally {
            if bitmap
                Gdip_DisposeImage(bitmap)
            Gdip_Shutdown(token)
        }
    }
}
