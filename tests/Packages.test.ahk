#Requires AutoHotkey v2.0

#Include ..\Lib\HubModel.ahk

#Include ..\Lib\Desktop.ahk

#Include ..\Lib\framework\RobloxEnvironment.ahk



try {

    MacroPackages.Root := A_ScriptDir "\..\test-results\packages-" A_TickCount

    MacroPackages.Bundled := MacroPackages.Root "\supplied"

    MacroPackages.Cached := 0

    MacroHub.Config["developer"] := 1

    created := MacroPackages.New(), id := created["package"]

    Assert(PantheonVersion.Compare("1.0-beta.10", "1.0-beta.2") > 0, "numeric beta versions compare correctly")
    Assert(PantheonVersion.Compare("1.0", "1.0-beta.1") > 0, "stable release is newer than beta")
    Assert(PantheonVersion.Compare("1.0.0-beta.1", "1.0-beta.1") == 0, "optional patch version normalizes")
    versionPackage := MacroPackages.Read(MacroPackages.Path(id))["package"]
    Assert(versionPackage["minPantheonVersion"] == PantheonVersion.Current, "new packages carry current minimum version")
    versionPackage["minPantheonVersion"] := "1.0-beta.3", blocked := false
    try MacroPackages.Validate(versionPackage)
    catch Error as err
        blocked := InStr(err.Message, "requires Pantheon") > 0
    Assert(blocked, "newer package requirements are blocked before installation")
    versionPackage["minPantheonVersion"] := "1.0-beta.1"
    MacroPackages.Validate(versionPackage)

    Assert(MacroPackages.Has(id), "new definitions register as macros")

    definition := created["definition"]

    definition["name"] := "Example TD"

    definition["icon"] := "raids"

    definition["settings"] := Map("stage", Map("label", "Stage", "type", "select", "default", "stage-one", "options", [Map("value", "stage-one", "label", "Stage 1", "target", ""), Map("value", "stage-two", "label", "Stage 2", "target", "")]))

    MacroPackages.Save(id, definition, 1)

    Assert(MacroPackages.Load(id)["definition"]["icon"] == "raids", "bundled icon survives saving")

    Assert(MacroPackages.Catalog(true)[1]["icon"] == "raids", "dashboard receives selected icon")

    MacroPackages.SaveValues(id, Map("stage", "stage-two"))

    Assert(MacroPackages.Values(id)["stage"] == "stage-two", "per-macro dashboard settings persist")

    Assert(MacroPackages.Load(id)["definition"]["settings"]["stage"]["default"] == "stage-one", "private saved settings do not replace exported defaults")

    package := Map("format", "pantheon-macro", "version", 1, "id", "macro-community-example", "definition", definition)

    text := JSON.stringify(package), preview := MacroPackages.Preview(text)

    Assert(!MacroPackages.Has(package["id"]), "reviewing imports does not install them")

    Assert(preview["name"] == "Example TD" && preview["settings"] == 1, "import preview shows macro metadata")

    installed := MacroPackages.Install(text)

    Assert(MacroHub.Mode(installed["package"]) == installed["package"], "imported definition is an allowed dashboard macro")

    plan := MacroHub.LaunchPlan(installed["package"])

    Assert(InStr(plan["path"], "framework\Worker.ahk"), "data macros use the fixed application worker")

    failed := false

    try MacroPackages.Install(text)

    catch Error

        failed := true

    Assert(failed, "imports cannot overwrite installed macros")

    package["id"] := "..\escape"

    RejectPackage(package, "path traversal rejected")

    package["id"] := "macro-unsafe"

    package["definition"]["workflows"]["main"]["steps"] := [Map("id", "run", "action", "run", "command", "cmd.exe")]

    RejectPackage(package, "script and shell actions rejected")

    package["definition"]["workflows"]["main"]["steps"] := [Map("id", "click", "action", "click-point", "x", 1, "y", 1, "button", "right")]

    RejectPackage(package, "enum spelling cannot make the editor and runtime disagree")

    package["definition"]["workflows"]["main"]["steps"] := []

    package["definition"]["icon"] := "https://invalid.test/icon.png"

    RejectPackage(package, "external icon URLs rejected")

    package["definition"]["icon"] := "..\escape.png"

    RejectPackage(package, "icon paths rejected")

    package["definition"]["icon"] := "raids"

    package["secret"] := "not-allowed"

    RejectPackage(package, "undeclared package fields rejected")

    nested := ""

    loop 65

        nested .= "["

    loop 65

        nested .= "]"

    failed := false

    try MacroPackages.Parse(nested)

    catch Error as err

        failed := InStr(err.Message, "nesting")

    Assert(failed, "deep JSON is rejected before native parsing")

    package.Delete("secret"), package["id"] := "macro-shipped-example"

    ProfileStore.WriteJson(MacroPackages.Bundled "\" package["id"] ".json", package)

    Assert(MacroPackages.Load(package["id"])["source"] == "bundled", "definitions can ship with Pantheon without executable plugins")

    d := MacroPackages.Load(package["id"])["definition"], d["name"] := "Local edit"

    MacroPackages.Save(package["id"], d, 0)

    Assert(MacroPackages.Read(MacroPackages.Bundled "\" package["id"] ".json")["definition"]["name"] == "Example TD", "local edits preserve shipped definitions")

    MacroPackages.Catalog(true)

    Assert(MacroPackages.Catalog().Length == 3, "created, imported and supplied macros coexist")

    second := MacroPackages.New()

    Assert(second["package"] != id && RegExMatch(second["package"], "^macro-[0-9a-f]{32}$"), "new macros have distinct portable identities")

    environment := RobloxFlowEnvironment(0, (*) => 0), failed := false

    try environment.Check()

    catch Error

        failed := true

    Assert(failed, "runtime rejects missing or unrelated windows")

    FileAppend("PASS: authored/imported/bundled data macros, dashboard registration, isolated settings, fixed worker, no overwrite, traversal/command/unknown-field rejection, shipped override preservation.`n", "*")

} catch Error as err {

    FileAppend("FAIL: " err.Message " (" err.File ":" err.Line ")`n", "**")

    ExitApp(1)

}

ExitApp(0)

RejectPackage(raw, message) {

    failed := false

    try MacroPackages.Parse(JSON.stringify(raw))

    catch Error

        failed := true

    Assert(failed, message)

}

Assert(value, message) {

    if !value

        throw Error(message)

}
