#Requires AutoHotkey v2.0
class PlacementPlan {
    static RouteId(id) {
        if !(id is String) || !RegExMatch(id, "^[-a-z0-9]{1,48}$")
            throw ValueError("Invalid route identifier.")
        return id
    }
    static Config(raw := unset) {
        raw := IsSet(raw) ? raw : Map()
        FlowSchema.Keys(raw, "targeting|autoUpgrade|autoUpgradeLevels")
        names := raw.Get("targeting", ["First", "Last", "Strongest", "Weakest"]), seen := Map()
        if !(names is Array) || !names.Length || names.Length > 16
            throw ValueError("Provide 1 to 16 targeting priorities in their in-game cycle order.")
        for name in names {
            FlowSchema.Text(name, 40, "targeting priority")
            if Trim(name) == "" || seen.Has(name)
                throw ValueError("Targeting names must be unique and nonempty.")
            seen[name] := true
        }
        return Map("targeting", names, "autoUpgrade", ProfileStore.Int(raw.Get("autoUpgrade", 0), 0, 1, "Auto upgrade support"), "autoUpgradeLevels", ProfileStore.Int(raw.Get("autoUpgradeLevels", 3), 1, 10, "Auto upgrade priorities"))
    }
    static Validate(raw, strict := false, capabilities := unset) {
        if !(raw is Map) || raw["version"] != 1 || !(raw["routes"] is Array) || !raw["routes"].Length || raw["routes"].Length > 60
            throw ValueError("Invalid placement setup.")
        cfg := IsSet(capabilities) ? this.Config(capabilities) : 0, ids := Map(), routes := []
        for route in raw["routes"] {
            id := this.RouteId(route["id"])
            if ids.Has(id)
                throw ValueError("Duplicate route.")
            ids[id] := true
            FlowSchema.Text(route["name"], 80, "route name")
            if Trim(route["name"]) == "" || !(route["teams"] is Array) || route["teams"].Length != 8
                throw ValueError("Each named route requires eight teams.")
            teams := []
            for team in route["teams"] {
                if !(team["steps"] is Array) || team["steps"].Length > 200
                    throw ValueError("A team supports at most 200 match steps.")
                steps := [], seen := Map(), starts := 0
                for action in team["steps"] {
                    if !(action["id"] is String) || !RegExMatch(action["id"], "^[-a-zA-Z0-9]{1,64}$") || seen.Has(action["id"])
                        throw ValueError("Invalid or duplicate match step.")
                    seen[action["id"]] := true
                    kind := FlowSchema.Enum(action["kind"], ["start", "place", "reconfigure", "upgrade", "sell", "wait"], "match action")
                    starts += kind == "start" ? 1 : 0
                    link := action.Get("placement", "")
                    if !(link is String) || (link != "" && !RegExMatch(link, "^[-a-zA-Z0-9]{1,64}$"))
                        throw ValueError("Invalid placed-unit reference.")
                    steps.Push(Map("id", action["id"], "kind", kind, "enabled", ProfileStore.Int(action.Get("enabled", 1), 0, 1, "Action enabled"),
                        "slot", ProfileStore.Int(action["slot"], 1, 6, "Unit slot"), "x", ProfileStore.Int(action["x"], 0, 799, "X"), "y", ProfileStore.Int(action["y"], 0, 599, "Y"),
                        "delayMs", ProfileStore.Int(action["delayMs"], 0, 600000, "Delay"), "repeat", ProfileStore.Int(action["repeat"], 1, 20, "Repeats"),
                        "timeoutMs", ProfileStore.Int(action["timeoutMs"], 1000, 180000, "Placement timeout"), "placement", link,
                        "targeting", ProfileStore.Int(action.Get("targeting", 0), 0, 15, "Targeting priority"), "changeTargeting", ProfileStore.Int(action.Get("changeTargeting", 1), 0, 1, "Change targeting"),
                        "autoUpgrade", ProfileStore.Int(action.Get("autoUpgrade", kind == "reconfigure" ? -1 : 0), kind == "reconfigure" ? -1 : 0, 10, "Auto upgrade priority")))
                }
                if starts != 1
                    throw ValueError("Each team requires exactly one Start Game step.")
                places := Map(), active := Map()
                for action in steps
                    if action["kind"] == "place"
                        places[action["id"]] := action
                for action in steps {
                    kind := action["kind"]
                    if kind == "upgrade" || kind == "sell" || kind == "reconfigure" {
                        if action["placement"] == "" {
                            matches := []
                            for place in places
                                if places[place]["slot"] == action["slot"] && places[place]["x"] == action["x"] && places[place]["y"] == action["y"]
                                    matches.Push(place)
                            if matches.Length == 1
                                action["placement"] := matches[1]
                        }
                        if places.Has(action["placement"]) {
                            target := places[action["placement"]]
                            action["slot"] := target["slot"], action["x"] := target["x"], action["y"] := target["y"]
                        } else if strict
                            throw ValueError("Select a placed unit for every Upgrade, Sell and Reconfigure action.")
                        if strict && action["enabled"] && !active.Has(action["placement"])
                            throw ValueError("Place the unit before its linked action; sold units cannot be reused.")
                        if kind == "sell" && action["enabled"] && active.Has(action["placement"])
                            active.Delete(action["placement"])
                    }
                    if kind == "place" && action["enabled"]
                        active[action["id"]] := true
                    if strict && cfg && action["enabled"] && (kind == "place" || kind == "reconfigure") {
                        if (kind == "place" || action["changeTargeting"]) && action["targeting"] >= cfg["targeting"].Length
                            throw ValueError("Targeting priority is not supported by this macro.")
                        if action["autoUpgrade"] > 0 && (!cfg["autoUpgrade"] || action["autoUpgrade"] > cfg["autoUpgradeLevels"])
                            throw ValueError("This macro does not support that auto upgrade priority.")
                    }
                }
                teams.Push(Map("steps", steps))
            }
            routes.Push(Map("id", id, "name", route["name"], "parent", route.Get("parent", ""), "team", ProfileStore.Int(route["team"], 1, 8, "Team"), "teams", teams))
        }
        for route in routes {
            parent := route["parent"]
            if parent == ""
                continue
            this.RouteId(parent)
            if parent == route["id"] || !ids.Has(parent)
                throw ValueError("Invalid placement map parent.")
            for candidate in routes
                if candidate["id"] == parent && candidate["parent"] != ""
                    throw ValueError("Placement maps support one child level.")
        }
        if !ids.Has(raw["selectedRoute"])
            throw ValueError("Selected route does not exist.")
        return Map("version", 1, "selectedRoute", raw["selectedRoute"], "useShared", ProfileStore.Int(raw.Get("useShared", 0), 0, 1, "Shared placements"), "routes", routes)
    }
}
