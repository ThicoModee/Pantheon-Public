#Requires AutoHotkey v2.0

#Include %A_LineFile%\..\Schema.ahk
#Include %A_LineFile%\..\..\Version.ahk



class MacroPackages {

    static Root := A_ScriptDir "\data\macros"

    static Bundled := A_ScriptDir "\macros"

    static Cached := 0

    static Warnings := []

    static ValidId(id) => id is String && RegExMatch(id, "^macro-[a-z0-9][a-z0-9-]{0,40}$")

    static Path(id) {

        if !this.ValidId(id)

            throw ValueError("Invalid macro identifier.")

        return this.Root "\" id ".json"

    }

    static Has(id) => this.ValidId(id) && (FileExist(this.Path(id)) || FileExist(this.Bundled "\" id ".json"))

    static Read(path) {

        if FileGetSize(path) > 500000

            throw Error("Macro configuration exceeds 500 KB.")

        return this.ParseJson(FileRead(path, "UTF-8"))

    }

    static Validate(raw) {

        FlowSchema.Keys(raw, "format|version|id|definition|minPantheonVersion")
        if raw.Has("minPantheonVersion")
            PantheonVersion.Require(raw["minPantheonVersion"])

        if !(raw["format"] == "pantheon-macro") || !this.ValidId(raw["id"])

            throw ValueError("Unsupported Pantheon macro configuration.")

        FlowSchema.Int(raw["version"], 1, 1, "Macro format version")

        PlayControls.Upgrade(raw["definition"])
        FlowSchema.Validate(raw["definition"])

        if Trim(raw["definition"]["name"]) == ""

            throw ValueError("Give the macro a name.")

        if !raw["definition"].Has("entry")

            throw ValueError("Choose a starting sequence for the macro.")

        return raw

    }

    static Load(id) {

        path := this.Path(id)

        if FileExist(path) {

            saved := this.Read(path), package := this.Validate(saved["package"])

            revision := FlowSchema.Int(saved["revision"], 1, 1000000, "Macro revision")

        } else {

            package := this.Validate(this.Read(this.Bundled "\" id ".json")), revision := 0

        }

        if package["id"] != id

            throw Error("Macro identity does not match its file.")

        return Map("package", id, "definition", package["definition"], "revision", revision, "source", revision ? "local" : "bundled")

    }

    static Catalog(force := false) {

        if this.Cached && !force

            return this.Cached

        found := Map(), result := []

        this.Warnings := []

        for folder in [this.Bundled, this.Root] {

            if !DirExist(folder)

                continue

            loop files folder "\macro-*.json" {

                SplitPath(A_LoopFileName, , , , &id)

                if this.ValidId(id)

                    found[id] := true

            }

        }

        for id in found {

            if result.Length >= 64 {

                this.Warnings.Push("Only the first 64 authored macros were loaded.")

                break

            }

            try {

                loaded := this.Load(id)

                result.Push(Map("id", id, "name", loaded["definition"]["name"], "icon", loaded["definition"].Get("icon", "pantheon"), "custom", 1, "installed", 1, "opened", 0, "seconds", 0))

            } catch Error as err

                this.Warnings.Push("Could not load " id ": " err.Message)

        }

        return this.Cached := result

    }

    static Write(id, definition, revision) {

        package := this.Validate(Map("format", "pantheon-macro", "version", 1, "minPantheonVersion", PantheonVersion.Current, "id", id, "definition", definition))

        raw := Map("package", package, "revision", revision)

        if StrPut(JSON.stringify(raw), "UTF-8") > 500000

            throw Error("Macro configuration exceeds 500 KB.")

        ProfileStore.WriteJson(this.Path(id), raw)

        this.Cached := 0

        return this.Load(id)

    }

    static New() {

        this.RequireDeveloper()

        if this.Catalog().Length >= 64

            throw Error("A workspace supports up to 64 authored macros.")

        index := this.Catalog().Length+1

        guid := Buffer(16)

        if DllCall("ole32\CoCreateGuid", "ptr", guid) != 0

            throw Error("Could not create a unique macro identity.")

        id := "macro-"

        loop 16

            id .= Format("{:02x}", NumGet(guid, A_Index-1, "uchar"))

        definition := Map("version", 1, "name", "New macro " index, "game", "roblox-td", "mode", "custom", "entry", "main", "runMode", "once", "icon", "pantheon",

            "client", Map("width", 800, "height", 600), "targets", Map(), "settings", Map(), "workflows", Map("main", Map("name", "Main sequence", "steps", [])))

        return this.Write(id, definition, 1)

    }

    static Save(id, definition, revision) {

        this.RequireDeveloper()

        FlowSchema.Int(revision, 0, 1000000, "Editor revision")

        if HubEngine.Busy()

            throw Error("Stop the macro before changing its definition.")

        current := this.Load(id)

        if revision != current["revision"]

            throw Error("The macro changed elsewhere. Reload before saving.")

        FlowSchema.Validate(definition)

        path := this.Root "\settings\" id ".json", values := FileExist(path) ? this.Read(path) : Map(), clean := Map(), warnings := []

        for key, spec in FlowSettings.Specs(definition) {

            try clean[key] := FlowSettings.Value(spec, values.Get(key, spec["default"]))

            catch Error {

                clean[key] := spec["default"]

                warnings.Push("Reset setting to its default: " spec["label"])

            }

        }

        result := this.Write(id, definition, revision+1)

        if FileExist(path)

            ProfileStore.WriteJson(path, clean)

        result["warnings"] := warnings

        return result

    }

    static Parse(text) {

        return this.Validate(this.ParseJson(text))

    }

    static ParseJson(text) {

        if !(text is String) || StrPut(text, "UTF-8") > 500000

            throw ValueError("Macro text exceeds 500 KB.")

        quoted := false, escaped := false, depth := 0, nodes := 0

        loop parse, text {

            c := A_LoopField

            if quoted {

                if escaped

                    escaped := false

                else if c == "\"

                    escaped := true

                else if c == '"'

                    quoted := false

            } else if c == '"'

                quoted := true

            else if c == "{" || c == "[" {

                if ++depth > 64 || ++nodes > 16384

                    throw ValueError("Macro JSON nesting or size limit exceeded.")

            } else if c == "}" || c == "]" {

                if --depth < 0

                    throw ValueError("Invalid macro JSON.")

            }

        }

        if quoted || depth != 0

            throw ValueError("Invalid macro JSON.")

        return JSON.parse(text)

    }

    static RequireDeveloper() {

        if !MacroHub.Config.Get("developer", 0)

            throw Error("Enable developer mode to author macro configurations.")

    }

    static Preview(text) {

        p := this.Parse(text), d := p["definition"]

        actions := Map()

        for flow in d["workflows"]

            this.CountActions(d["workflows"][flow]["steps"], actions)

        return Map("id", p["id"], "name", d["name"], "game", d["game"], "icon", d.Get("icon", "pantheon"), "entry", d["entry"], "settings", FlowSettings.Specs(d).Count,

            "sequences", d["workflows"].Count, "targets", d["targets"].Count, "exists", this.Has(p["id"]) ? 1 : 0, "runMode", d.Get("runMode", "once"), "actions", actions)

    }

    static CountActions(steps, actions) {

        for step in steps {

            action := step["action"]

            actions[action] := actions.Get(action, 0)+1

            for field in ["steps", "thenSteps", "elseSteps"]

                if step.Has(field)

                    this.CountActions(step[field], actions)

        }

    }

    static Install(text) {

        if HubEngine.Busy()

            throw Error("Stop the macro before importing another configuration.")

        p := this.Parse(text)

        if this.Has(p["id"])

            throw Error("A macro with this identity is already installed. Existing macros are not overwritten by imports.")

        if this.Catalog().Length >= 64

            throw Error("A workspace supports up to 64 authored macros.")

        return this.Write(p["id"], p["definition"], 1)

    }

    static Export(id) {

        d := this.Load(id)["definition"]

        text := JSON.stringify(Map("format", "pantheon-macro", "version", 1, "minPantheonVersion", PantheonVersion.Current, "id", id, "definition", d))

        A_Clipboard := text

        return Map("copied", 1)

    }

    static ExportDraft(raw) {

        this.RequireDeveloper()

        FlowSchema.Keys(raw, "id|definition")

        p := this.Validate(Map("format", "pantheon-macro", "version", 1, "minPantheonVersion", PantheonVersion.Current, "id", raw["id"], "definition", raw["definition"]))

        text := JSON.stringify(p)

        if StrPut(text, "UTF-8") > 500000

            throw Error("Macro configuration exceeds 500 KB.")

        A_Clipboard := text

        return Map("copied", 1)

    }

    static Values(id) {

        definition := this.Load(id)["definition"], path := this.Root "\settings\" id ".json"

        return FlowSettings.Values(definition, FileExist(path) ? this.Read(path) : Map())

    }

    static SaveValues(id, values) {

        if HubEngine.Busy()

            throw Error("Stop the macro before saving settings.")

        clean := FlowSettings.Values(this.Load(id)["definition"], values)

        ProfileStore.WriteJson(this.Root "\settings\" id ".json", clean)

        return clean

    }

}
