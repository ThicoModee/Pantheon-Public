#Requires AutoHotkey v2.0

class WorkflowComponents {
    static Execute(r, step, location) {
        if step["action"] == "setting-call" {
            r.Execute(step["routes"][r.Values[step["setting"]]])
            return
        }
        if step["action"] == "click-wait" {
            condition := Map("operator", "all", "checks", [Map("target", step["ready"], "state", "present")])
            loop step["attempts"] {
                if r.Find(step["ready"], 0)
                    return
                found := r.Find(step["target"], step["timeoutMs"])
                if !found
                    throw FlowImageError("Click and wait could not find its click target (" location ").")
                r.Environment.Click(found["x"], found["y"], step["button"])
                if r.WaitCondition(condition, step["timeoutMs"])
                    return
                if A_Index < step["attempts"]
                    r.Wait(step["intervalMs"])
            }
            throw FlowImageError("Click and wait did not detect its ready image (" location ").")
        }
        r.Deadlines.Push({End: A_TickCount+step["timeoutMs"], Owner: location})
        try {
            if step["action"] == "scroll-option" {
                target := FlowSettings.Option(FlowSettings.Spec(r.Definition, step["setting"]), r.Values[step["setting"]])["target"]
                loop step["maxScrolls"]+1 {
                    if found := r.Find(target, 0) {
                        r.Environment.Click(found["x"], found["y"], "Left")
                        return
                    }
                    if A_Index > step["maxScrolls"]
                        break
                    r.Environment.Move(step["x"], step["y"])
                    r.Environment.Scroll(step["direction"], 1)
                    r.Wait(step["intervalMs"])
                }
                throw FlowImageError("Selected option was not found within the scroll limit (" location ").")
            }
            loop {
                if r.Find(step["ready"], 0)
                    return
                if found := r.Find(step["target"], 0)
                    r.Environment.Click(found["x"], found["y"], step["button"])
                r.Wait(step["intervalMs"])
            }
        } catch FlowLoopTimeout as err {
            if err.Owner != location
                throw err
            throw FlowImageError("Component timed out before its ready image was found (" location ").")
        } finally r.Deadlines.Pop()
    }
}
